---
name: buy-domain-and-deploy
description: Take a shower idea from name → live HTTPS site in under 5 minutes. Buys a .com via Namecheap, adds the zone to Cloudflare, points DNS at the VPS, configures Caddy, deploys a placeholder. Use when EJ says "buy a domain", "spin up a site for X", "register Y.com and put something at it", or describes wanting a website without specifying infrastructure.
allowed-tools: Bash, Read, Edit, Write
---

# buy-domain-and-deploy

Full pipeline: idea → registered domain → live HTTPS page on EJ's VPS, all autonomous.

## Detect environment first

Before doing anything, run `hostname` once. The skill works on two machines and the deploy phase differs:

| Hostname | Role | NAMECHEAP_CLIENT_IP | Caddy/file ops |
|---|---|---|---|
| `MacBookPro` | Laptop | `151.202.21.58` | Wrap shell commands in `ssh vps '...'` |
| `ejfvps` | VPS | `208.113.130.118` | Run shell commands directly (no SSH wrapper, use `sudo` where shown) |

Anywhere this skill says `ssh vps 'cmd'`, on the VPS just run `cmd`. Anywhere it sets `NAMECHEAP_CLIENT_IP=151.202.21.58`, on the VPS substitute the VPS IP. The Namecheap MCP env vars are already set per-machine via `claude mcp add`, so the registered MCP tools (`mcp__namecheap__*`) work the same on both.

## When to invoke

- "Buy [domain].com"
- "Spin up a site for [thing]"
- "Register a domain for my friend's [project]"
- "I want a quick landing page at [domain]"

If the user just wants a domain *checked* (not bought), call `domain_check` from the namecheap MCP and stop there.

## What's already wired up

| Piece | Where | Notes |
|---|---|---|
| Namecheap MCP | `~/code/namecheap-mcp` (registered as `mcp__namecheap__*`) | $20/week trailing cap, ledger at `~/.config/namecheap-mcp/ledger.json` |
| Namecheap API key | env on the registered MCP | Whitelisted IPs: laptop `151.202.21.58`, VPS `208.113.130.118` |
| Registrant contacts | `~/.config/namecheap-mcp/contacts.json` | 600 perms, EJ's real address |
| Cloudflare token | `~/.config/cloudflare/token` | 600 perms, account `deffa184038440afc07f53b5e7583a97`. Permissions include Account → Account Settings → Edit (the magic one that lets us create zones via API) |
| VPS Caddy | `vps:/etc/caddy/Caddyfile`, `auto_https off` | CF terminates TLS, Caddy serves HTTP. Reload via `sudo systemctl reload caddy` |
| VPS web root convention | `/var/www/<domain>/` owned `debian:debian` | |

## The flow

### 1. Check + quote (no charge)

```sh
# In a session where the namecheap MCP is loaded, just call domain_check
# and domain_buy without confirm. Otherwise direct CLI:
cd ~/code/namecheap-mcp
NAMECHEAP_API_USER=ejfox \
NAMECHEAP_API_KEY=$(grep NAMECHEAP_API_KEY ~/.claude.json | head -1 | cut -d'"' -f4) \
NAMECHEAP_CLIENT_IP=151.202.21.58 \
node -e "import('./src/namecheap.js').then(({checkDomains, getPricing}) => Promise.all([checkDomains(['DOMAIN.com']), getPricing('com')])).then(r => console.log(JSON.stringify(r,null,2)))"
```

Show EJ the price and current cap status. **Always wait for explicit go-ahead before purchasing** — real money.

### 2. Register the domain

```sh
cd ~/code/namecheap-mcp
NAMECHEAP_API_USER=ejfox NAMECHEAP_API_KEY=... NAMECHEAP_CLIENT_IP=151.202.21.58 \
node -e "
import('./src/namecheap.js').then(async ({registerDomain}) => {
  const { loadContacts } = await import('./src/contacts.js');
  const { checkCap, record } = await import('./src/ledger.js');
  const contacts = await loadContacts();
  await checkCap(PRICE);
  const r = await registerDomain({ domain: 'DOMAIN.com', years: 1, contacts });
  await record({ domain: 'DOMAIN.com', amount: r.chargedAmount, years: 1, orderId: r.orderId, transactionId: r.transactionId });
  console.log(JSON.stringify(r, null, 2));
});
"
```

WhoisGuard auto-enabled. ICANN fee ($0.20) added on top of `.com` price (~$11.28 → $11.48 charged).

### 3. Add zone to Cloudflare

```sh
TOKEN=$(cat ~/.config/cloudflare/token)
ACCOUNT_ID=deffa184038440afc07f53b5e7583a97
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  https://api.cloudflare.com/client/v4/zones \
  -d '{"name":"DOMAIN.com","account":{"id":"'$ACCOUNT_ID'"},"type":"full"}'
```

The response includes `result.id` (zone ID) and `result.name_servers` (the CF NS pair to give Namecheap, e.g., `dana.ns.cloudflare.com` + `norm.ns.cloudflare.com`). **Capture both.**

### 4. Point Namecheap nameservers at Cloudflare

```sh
cd ~/code/namecheap-mcp
NAMECHEAP_API_USER=ejfox NAMECHEAP_API_KEY=... NAMECHEAP_CLIENT_IP=151.202.21.58 \
node -e "import('./src/namecheap.js').then(({setNameservers}) => setNameservers('DOMAIN.com', ['NS1', 'NS2'])).then(r => console.log(r))"
```

### 5. DNS records + SSL settings at Cloudflare

```sh
TOKEN=$(cat ~/.config/cloudflare/token)
ZONE_ID=<from step 3>
VPS_IP=208.113.130.118

# Apex + www, both proxied
for NAME in '@' 'www'; do
  curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
    "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
    -d "{\"type\":\"A\",\"name\":\"$NAME\",\"content\":\"$VPS_IP\",\"proxied\":true,\"ttl\":1}"
done

# SSL flexible (CF↔origin plain HTTP, since Caddy is auto_https off)
curl -s -X PATCH -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/settings/ssl" -d '{"value":"flexible"}'

# Force HTTPS for visitors
curl -s -X PATCH -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/settings/always_use_https" -d '{"value":"on"}'
```

CF activates the zone within seconds once it sees its NS at the registrar — usually live before this step finishes.

### 6. Configure VPS Caddy + drop placeholder

```sh
ssh vps 'sudo cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.bak.$(date +%Y%m%d-%H%M%S)'
ssh vps 'sudo mkdir -p /var/www/DOMAIN.com && sudo chown debian:debian /var/www/DOMAIN.com'

# Write index.html — see assets/placeholder-template.html for the vulpes-aesthetic template
ssh vps 'cat > /tmp/idx.html' << 'HTML'
... (use placeholder-template.html as starting point) ...
HTML
ssh vps 'sudo mv /tmp/idx.html /var/www/DOMAIN.com/index.html && sudo chown debian:debian /var/www/DOMAIN.com/index.html'

# Insert Caddy block before "# === SMART CATCH-ALL ==="
ssh vps "sudo python3 -c \"
import pathlib
p = pathlib.Path('/etc/caddy/Caddyfile')
s = p.read_text()
block = '''
\t@SLUG host DOMAIN.com www.DOMAIN.com
\thandle @SLUG {
\t\troot * /var/www/DOMAIN.com
\t\tfile_server
\t}

'''
marker = '\t# === SMART CATCH-ALL ==='
if '@SLUG' not in s and marker in s:
    p.write_text(s.replace(marker, block + marker))
    print('inserted')
\""

ssh vps 'sudo caddy validate --config /etc/caddy/Caddyfile && sudo systemctl reload caddy'
```

### 7. Verify

```sh
# Direct VPS via Host header (proves vhost wired)
curl -s -H "Host: DOMAIN.com" http://208.113.130.118/ | head -5

# Through CF
curl -sI https://DOMAIN.com/ | head -5
```

Expect `HTTP/2 200`. If `521`, CF reached origin but origin refused (Caddy block missing or wrong). If `404`, CF didn't activate yet (wait 30s, retry). If `1001`, NS still propagating at registrar (usually <2 min).

## Things that will go wrong

- **NS records seem wrong at Namecheap:** their API expects nameservers as a comma-separated string, not an array. The `setNameservers` helper in `namecheap-mcp` handles this — use it instead of raw API.
- **CF zone create returns "com.cloudflare.api.account.zone.create" error:** the token is missing `Account → Account Settings → Edit`. That's the permission that backdoors zone creation for individual accounts.
- **`Caddyfile validate` fails:** check your Python heredoc didn't break tab indentation. Caddy is whitespace-sensitive in some places.
- **Cap exceeded:** the ledger refuses to charge. Tell EJ. If he wants to override, he can edit `~/.config/namecheap-mcp/ledger.json` directly (it's just JSON), or bump `NAMECHEAP_WEEKLY_CAP` via `claude mcp` config.

## Placeholder template

Use `assets/placeholder-template.html` as the starting HTML. It uses EJ's vulpes palette (`#000` bg, `#e60067` accent, `#6eedf7` link, mono font), responsive, `noindex/nofollow`, and includes a `CONTACT_EMAIL_HERE` stub for filling in later.

## After it's live

- Mention the live URL with `HTTP/2 200` confirmation.
- Offer to update the weekly note with what shipped (use `mcp__mcp-obsidian__obsidian_append_content` against the current week's note).
- If the site is for a real human (not a personal project), suggest filling in the `CONTACT_EMAIL_HERE` stub before sharing the URL.
- Don't auto-schedule a follow-up unless EJ specifically asked for one.
