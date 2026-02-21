# MCP GUI Diagnostic Test — Do NOT Do Any Work

This tests that MCP tools (windows-mcp) work inside a Ralph loop.
Do NOT pick up any beads or modify any code.

## Steps

1. Print: "MCP GUI diagnostic starting"
2. Launch the app in the background:
   ```
   .venv/Scripts/python -m src.app --fake-ble --windowed &
   ```
3. Wait 5 seconds for the window to appear (use the Wait tool or `sleep 5`)
4. Take a Snapshot using the MCP windows-mcp Snapshot tool with `use_vision=true`
5. Verify the snapshot shows the Ergofigure Eye Demonstration window
6. Print what you see: window title, whether the graph area is visible, whether the toolbar is present
7. Kill the app process:
   ```
   taskkill //F //IM python.exe
   ```
8. Print: "MCP GUI diagnostic complete"
9. Output `<promise>COMPLETE</promise>`

Do NOT create branches, commits, or modify any files.
