exports.execute = async (args) => {
    // args => https://egomobile.github.io/vscode-powertools/api/interfaces/contracts.workspacecommandscriptarguments.html

    // s. https://code.visualstudio.com/api/references/vscode-api
    const vscode = args.require('vscode');

    const terminal = vscode.window.activeTerminal;
    const text1 = "/home/diminiminim/love2d.AppImage /home/diminiminim/GameDev/dungeon/src";  
    
    terminal.sendText(text1);
};