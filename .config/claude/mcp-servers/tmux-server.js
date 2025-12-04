#!/usr/bin/env node
/**
 * MCP Server for tmux control
 * Allows Claude Code to send commands to tmux panes, create panes, etc.
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { execSync } from "child_process";

const server = new Server(
  {
    name: "tmux-control",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Helper to run tmux commands
function tmux(cmd) {
  try {
    return execSync(`tmux ${cmd}`, { encoding: "utf8" }).trim();
  } catch (error) {
    throw new Error(`tmux command failed: ${error.message}`);
  }
}

// Get current pane ID from environment
const CURRENT_PANE = process.env.TMUX_PANE || null;

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "tmux_current_pane",
        description: "Get info about the current pane Claude Code is running in",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "tmux_list_panes",
        description: "List all tmux panes with their IDs, titles, and current commands. Current pane is marked with *",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "tmux_send_keys",
        description: "Send keys/commands to a specific tmux pane",
        inputSchema: {
          type: "object",
          properties: {
            pane: {
              type: "string",
              description: "Pane ID (e.g., '%2' or '0:6.2')",
            },
            keys: {
              type: "string",
              description: "Keys to send (will auto-add Enter at end)",
            },
            literal: {
              type: "boolean",
              description: "If true, send -l flag (literal keys, no special chars)",
              default: false,
            },
          },
          required: ["pane", "keys"],
        },
      },
      {
        name: "tmux_send_file",
        description: "Send file contents to a tmux pane",
        inputSchema: {
          type: "object",
          properties: {
            pane: {
              type: "string",
              description: "Pane ID (e.g., '0:6.2')",
            },
            content: {
              type: "string",
              description: "Content to send",
            },
            clear_first: {
              type: "boolean",
              description: "Clear pane before sending",
              default: true,
            },
          },
          required: ["pane", "content"],
        },
      },
      {
        name: "tmux_create_pane",
        description: "Create a new tmux pane",
        inputSchema: {
          type: "object",
          properties: {
            direction: {
              type: "string",
              enum: ["horizontal", "vertical"],
              description: "Split direction",
            },
            title: {
              type: "string",
              description: "Optional pane title",
            },
          },
          required: ["direction"],
        },
      },
      {
        name: "tmux_kill_pane",
        description: "Kill a specific tmux pane",
        inputSchema: {
          type: "object",
          properties: {
            pane: {
              type: "string",
              description: "Pane ID to kill (e.g., '0:6.2')",
            },
          },
          required: ["pane"],
        },
      },
      {
        name: "tmux_send_diagram",
        description: "Send a mermaid diagram to a pane (uses mermaid-ascii)",
        inputSchema: {
          type: "object",
          properties: {
            pane: {
              type: "string",
              description: "Pane ID (e.g., '0:6.2')",
            },
            mermaid: {
              type: "string",
              description: "Mermaid diagram syntax (multiline format)",
            },
          },
          required: ["pane", "mermaid"],
        },
      },
    ],
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case "tmux_current_pane": {
        if (!CURRENT_PANE) {
          return {
            content: [
              {
                type: "text",
                text: "Not running in tmux (no TMUX_PANE env var)",
              },
            ],
          };
        }
        const info = tmux(
          `list-panes -a -F '#{pane_id}|#{session_name}:#{window_index}.#{pane_index}|#{pane_title}|#{pane_current_command}' | grep "^${CURRENT_PANE}"`
        );
        return {
          content: [
            {
              type: "text",
              text: `Current pane: ${info}`,
            },
          ],
        };
      }

      case "tmux_list_panes": {
        const panes = tmux(
          "list-panes -a -F '#{pane_id}|#{session_name}:#{window_index}.#{pane_index}|#{pane_title}|#{pane_current_command}'"
        );
        // Mark current pane with *
        const marked = panes
          .split("\n")
          .map((line) => {
            if (CURRENT_PANE && line.startsWith(CURRENT_PANE)) {
              return `* ${line}`;
            }
            return `  ${line}`;
          })
          .join("\n");
        return {
          content: [
            {
              type: "text",
              text: `Panes (* = current Claude Code pane):\n${marked}`,
            },
          ],
        };
      }

      case "tmux_send_keys": {
        const { pane, keys, literal } = args;
        const flags = literal ? "-l" : "";
        tmux(`send-keys ${flags} -t "${pane}" "${keys.replace(/"/g, '\\"')}" Enter`);
        return {
          content: [
            {
              type: "text",
              text: `Sent to pane ${pane}: ${keys}`,
            },
          ],
        };
      }

      case "tmux_send_file": {
        const { pane, content, clear_first } = args;
        if (clear_first) {
          tmux(`send-keys -t "${pane}" C-c`);
          tmux(`send-keys -t "${pane}" clear Enter`);
        }
        // Write to temp file and cat it
        const tmpFile = `/tmp/tmux-content-${Date.now()}.txt`;
        execSync(`echo "${content.replace(/"/g, '\\"')}" > ${tmpFile}`);
        tmux(`send-keys -t "${pane}" "cat ${tmpFile}" Enter`);
        execSync(`rm ${tmpFile}`);
        return {
          content: [
            {
              type: "text",
              text: `Sent content to pane ${pane}`,
            },
          ],
        };
      }

      case "tmux_create_pane": {
        const { direction, title } = args;
        const flag = direction === "horizontal" ? "-h" : "-v";
        const result = tmux(`split-window ${flag} -P -F "#{pane_id}"`);
        if (title) {
          tmux(`select-pane -t "${result}" -T "${title}"`);
        }
        return {
          content: [
            {
              type: "text",
              text: `Created pane: ${result}${title ? ` (${title})` : ""}`,
            },
          ],
        };
      }

      case "tmux_kill_pane": {
        const { pane } = args;
        tmux(`kill-pane -t "${pane}"`);
        return {
          content: [
            {
              type: "text",
              text: `Killed pane ${pane}`,
            },
          ],
        };
      }

      case "tmux_send_diagram": {
        const { pane, mermaid } = args;
        const tmpFile = `/tmp/mermaid-${Date.now()}.txt`;
        // Generate ASCII diagram
        execSync(
          `echo "${mermaid.replace(/"/g, '\\"')}" | mermaid-ascii -a > ${tmpFile}`
        );
        tmux(`send-keys -t "${pane}" C-c`);
        tmux(`send-keys -t "${pane}" "clear && cat ${tmpFile}" Enter`);
        execSync(`rm ${tmpFile}`);
        return {
          content: [
            {
              type: "text",
              text: `Sent diagram to pane ${pane}`,
            },
          ],
        };
      }

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return {
      content: [
        {
          type: "text",
          text: `Error: ${error.message}`,
        },
      ],
      isError: true,
    };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("tmux MCP server running on stdio");
}

main().catch((error) => {
  console.error("Server error:", error);
  process.exit(1);
});
