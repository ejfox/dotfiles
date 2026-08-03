//! Tiny inline-markup parser shared by both renderers.
//!
//!   `x`   -> Kbd     a key
//!   *x*   -> Em      emphasis (teal)
//!   **x** -> Bold    strong
//!   \c    -> literal c (escape any markup char, incl. a literal backtick)

#[derive(Debug, Clone, PartialEq)]
pub enum Seg {
    Text(String),
    Kbd(String),
    Em(String),
    Bold(String),
}

pub fn parse(s: &str) -> Vec<Seg> {
    let chars: Vec<char> = s.chars().collect();
    let mut out: Vec<Seg> = Vec::new();
    let mut buf = String::new();
    let mut i = 0;

    macro_rules! flush {
        () => {
            if !buf.is_empty() {
                out.push(Seg::Text(std::mem::take(&mut buf)));
            }
        };
    }

    while i < chars.len() {
        match chars[i] {
            '\\' if i + 1 < chars.len() => {
                buf.push(chars[i + 1]);
                i += 2;
            }
            '`' => {
                flush!();
                i += 1;
                let inner = take_until(&chars, &mut i, |c| c == '`');
                i += 1; // consume closing backtick (or past end)
                out.push(Seg::Kbd(inner));
            }
            '*' => {
                let bold = i + 1 < chars.len() && chars[i + 1] == '*';
                flush!();
                i += if bold { 2 } else { 1 };
                let mut inner = String::new();
                while i < chars.len() {
                    if chars[i] == '\\' && i + 1 < chars.len() {
                        inner.push(chars[i + 1]);
                        i += 2;
                        continue;
                    }
                    if bold {
                        if chars[i] == '*' && i + 1 < chars.len() && chars[i + 1] == '*' {
                            i += 2;
                            break;
                        }
                    } else if chars[i] == '*' {
                        i += 1;
                        break;
                    }
                    inner.push(chars[i]);
                    i += 1;
                }
                out.push(if bold { Seg::Bold(inner) } else { Seg::Em(inner) });
            }
            c => {
                buf.push(c);
                i += 1;
            }
        }
    }
    flush!();
    out
}

fn take_until(chars: &[char], i: &mut usize, stop: impl Fn(char) -> bool) -> String {
    let mut s = String::new();
    while *i < chars.len() && !stop(chars[*i]) {
        if chars[*i] == '\\' && *i + 1 < chars.len() {
            s.push(chars[*i + 1]);
            *i += 2;
        } else {
            s.push(chars[*i]);
            *i += 1;
        }
    }
    s
}

/// Flatten segments to their plain text (for search matching).
pub fn plain(segs: &[Seg]) -> String {
    segs.iter()
        .map(|s| match s {
            Seg::Text(t) | Seg::Kbd(t) | Seg::Em(t) | Seg::Bold(t) => t.as_str(),
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn kbd_and_em() {
        assert_eq!(
            parse("`zM`  shut *everything*"),
            vec![
                Seg::Kbd("zM".into()),
                Seg::Text("  shut ".into()),
                Seg::Em("everything".into()),
            ]
        );
    }

    #[test]
    fn bold_vs_em() {
        assert_eq!(
            parse("**M**ax / *soft*"),
            vec![
                Seg::Bold("M".into()),
                Seg::Text("ax / ".into()),
                Seg::Em("soft".into()),
            ]
        );
    }

    #[test]
    fn escaped_backticks() {
        assert_eq!(
            parse(r"gives *file \`\`\`code\`\`\`*"),
            vec![
                Seg::Text("gives ".into()),
                Seg::Em("file ```code```".into()),
            ]
        );
    }
}
