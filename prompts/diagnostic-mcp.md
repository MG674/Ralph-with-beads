# MCP GUI Diagnostic Test — Do NOT Do Any Work

This tests that MCP tools (windows-mcp) work inside a Ralph loop.
Do NOT pick up any beads or modify any code.

You MUST follow every step below IN ORDER and print the output of each step.

## Step 1
Print exactly: "MCP GUI diagnostic starting"

## Step 2
Launch the app in the background by running this command:
```
.venv/Scripts/python -m src.app --fake-ble --windowed &
```

## Step 3
Wait 5 seconds for the window to appear. Run: `sleep 5`

## Step 4
Take a screenshot using the MCP windows-mcp Snapshot tool.

## Step 5
Print what you see in the screenshot:
- Window title
- Whether the graph area is visible
- Whether the toolbar (Start/Stop/Settings buttons) is present
- Any other notable UI elements

## Step 6
Kill the app by running: `powershell -Command "Get-Process python -ErrorAction SilentlyContinue | Where-Object {$_.MainWindowTitle -ne ''} | Stop-Process -Force"`

## Step 7
Print exactly: "MCP GUI diagnostic complete"

## Step 8
Output exactly this on its own line (this is critical — the loop script looks for it):
<promise>COMPLETE</promise>

## Rules
- Do NOT create branches, commits, or modify any files
- Do NOT skip any step
- Print output for EVERY step
- The <promise>COMPLETE</promise> tag in Step 8 is MANDATORY — without it the loop will not terminate
