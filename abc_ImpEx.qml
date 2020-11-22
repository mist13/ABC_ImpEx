//=============================================================================
//
//  ABC import and export plugin via abc2xml and xml2abc
//  Based on abc_import (C)2013 Stephane Groleau (vgstef)
//  (Based on ABC Import by Nicolas Froment (lasconic))
//  Some of the code was heavily inspired by 
//  Run (C)2012 Werner Schweer and others, and Batch Convert
//  (C)2020 Michael Strasser
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
//=============================================================================

import QtQuick 2.1
import QtQuick.Dialogs 1.2
import QtQuick.Controls 1.0
import MuseScore 3.0
import FileIO 3.0
import Qt.labs.folderlistmodel 2.2

MuseScore {
    menuPath: "Plugins.ABC ImpEx"
    version: "1.1"
    description: qsTr("This plugin imports ABC notation from a file or the clipboard and exports the current score to ABC.\nExecutables of abc2xml and/or xml2abc are required.")
    requiresScore: false
    pluginType: "dialog"       
    
    QProcess {
        id: proc
        }
                            
    id:window
    width: 800; height: 520;
    
    property string pathImpEx : Qt.resolvedUrl(".")
    property string pathImpEx2: getLocalPath(pathImpEx)
    property string pathAbc2Xml
    property string pathXml2Abc
    
    property string installAbcText: QT_TR_NOOP("\n INSTALLATION\n ==========\n
        Copy abc2xml.py and/or xml2abc.py into this plugin's folder:
        %1\n
        Should you already have the files in a different location,
        enter their full path into the ini file in the same folder.\n\n
        If you are running Windows, make sure that Python is installed
        and that the path to Python is in your PATH environment variable.\n
        Alternatively, use abc2xml.exe and xm2abc.exe files instead.")
        
    property string infoAbcText: QT_TR_NOOP("\n IMPORT\n ======\n
            1. Paste ABC or select file using button 'Open'.\n
            2. Change ABC as desired and/or select part of it.\n
            3. Import into score using button 'Import'.
            \n EXPORT\n ======\n
            1. To translate active score, click button 'Export'.\n
            2. Change ABC as desired and/or select part of it.\n
            3. Save into file using button 'Save'.")
    
    FolderListModel { // List of converters in ImpEx folder 
        id: folderModel 
        folder: pathImpEx
        nameFilters: ["*.py", "*.exe"]
        }
        
    Timer { // Wait 25ms for list of files in ImpEx folder and look for converters 
        id: collectFiles
        interval: 25
        running: false
        onTriggered: {
            if (folderModel.count > 0) {
                var abc2xml2abc = ["abc2xml.py", "abc2xml.exe", "xml2abc.py", "xml2abc.exe"];
                var i = 0;
                var path = "";
                while (i < 4) {
                    if (folderModel.indexOf(pathImpEx+abc2xml2abc[i]) > -1) {
                       path = prepConvPath(pathImpEx+abc2xml2abc[i]);
                       if (i < 2) {
                           pathAbc2Xml = path;                       
                           i = 1;
                           }
                       else {
                           pathXml2Abc = path;
                           break;
                           }
                       }
                    i++
                    }
                }
            if (pathAbc2Xml == "" || pathXml2Abc == "") { // Check ini for missing converter path
                readIniFile();
                }
            if (pathAbc2Xml == "" && pathXml2Abc == "") { // Instructions if no converters                
                abcText.text = qsTr(installAbcText).arg(pathImpEx2);
                }
            else if (pathAbc2Xml.startsWith("python0") || pathXml2Abc.startsWith("python0")) { // Instructions if no python
                abcText.text = qsTr(installAbcText).arg(pathImpEx2);
                infoText.text = qsTr("Python not found!.\nPlease check your installation and\nenvironment variables.");
                userInfo.visible = true;
                }
            else              
                abcText.text = qsTr(infoAbcText); //contentAbcText;  
            }
        }

    FileIO { // ini
        id: iniFile
        source: pathImpEx + "abc_ImpEx.ini"
        onError: console.log("Ini: " + msg)
        } 
        
    onRun: {
        collectFiles.running = true; // Start looking for converters
        }
                
    FileIO { // Abc for import
        id: myFileAbc
        onError: console.log(msg + "  Filename = " + myFileAbc.source)
        }

    FileIO { // temp Xml for MuseScore
        id: myFile
        source: tempPath() + "/myFile.xml"
        onError: console.log(msg)
        }
    
    FileIO { // temp Abc for abc2xml
        id: myImpExAbc
        source: tempPath() + "/myImpExAbc.abc"
        onError: console.log(msg)
        }
        
    FileIO { // temp Xml for xml2abc
        id: myExportXml
        source: tempPath() + "/myExportXml.xml"
        onError: console.log(msg);
        }
            
    FileDialog { // Choose Abc file
        id: openDialog
        title: qsTr("Please choose a file")
        onAccepted: {
            var filename = openDialog.fileUrl;
            //console.log("You chose: " + filename)
            if(filename) {
                myFileAbc.source = filename;
                //read abc file and put it in the TextArea
                abcText.text = myFileAbc.read();
                }
            }
        }
                    
    FileDialog { // Save Abc as...
        id: saveDialog
        title: qsTr("Please select a destination")
        nameFilters: [ "Abc files (*.abc *.txt)", "All files (*)" ]
        selectExisting: false
        onAccepted: {
            var filename = saveDialog.fileUrl.toString();
            //console.log("You chose: " + filename)
            myImpExAbc.source = getLocalPath(filename);
            if (abcText.selectedText == "")
                myImpExAbc.write(abcText.text);
            else
                myImpExAbc.write(abcText.selectedText)
            myImpExAbc.source = tempPath() + "/myImpExAbc.abc"    
            //Qt.quit();
            }
        }
        
    Dialog { // Info popup  
        id: userInfo
        width: 400
        height: 120
        visible: false
        title: "ABC ImpEx"
        standardButtons: StandardButton.Ok
        Text {
            id: infoText
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 15
            }
        onAccepted: close();
        }

    Label { // Basic info and link to abc2xml and xml2abc
        id: textLabel
        wrapMode: Text.WordWrap
        text: qsTr("This plugin needs abc2xml and/or xml2abc from <a href='https://wim.vree.org/svgParse'>wim.vree.org</a> to work.")
        font.pointSize:11
        anchors.left: window.left
        anchors.top: window.top
        anchors.leftMargin: 18
        anchors.topMargin: 10
        onLinkActivated: Qt.openUrlExternally(link);
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }
    
    Text { // Display plugin version
        id: versionText
        text: "V 1.1"
        font.pointSize:10
        anchors.right: window.right
        anchors.top: window.top
        anchors.rightMargin: 17
        anchors.topMargin: 11
        }   
        
    // Where people can paste their ABC tune or where an ABC file is put when opened
    TextArea {
        id:abcText
        anchors.top: textLabel.bottom
        anchors.left: window.left
        anchors.right: window.right
        anchors.bottom: lbCheckBox.top // buttonOpenFile.top
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        width:parent.width
        height:400
        wrapMode: TextEdit.WrapAnywhere
        textFormat: TextEdit.PlainText
        }
        
    CheckBox {
        id: lbCheckBox
        text: " " + qsTr("score line-break = $")
        anchors.left: abcText.left
        anchors.bottom: buttonOpenFile.top
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        anchors.leftMargin: 12
        checked: false
        }
    
    Button { // Open Abc and display
        id : buttonOpenFile
        text: qsTranslate("QPlatformTheme", "Open") //qsTr("Open...")
        anchors.bottom: window.bottom
        anchors.left: abcText.left
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        anchors.leftMargin: 10
        onClicked: {
            openDialog.open();
            }
        }
        
    Button { // Import Abc into Xml
        id : buttonImport
        text: qsTranslate("QPlatformTheme", "Import") //qsTr("Import")
        anchors.bottom: window.bottom
        anchors.left: buttonOpenFile.right
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        anchors.leftMargin: 5
        onClicked: {
            if (pathAbc2Xml !== "" && pathAbc2Xml.startsWith("python0") == false) { // Check for converter and python
                if (abcText.text !== "" && abcText.text !== qsTr(installAbcText).arg(pathImpEx2) && abcText.text !== qsTr(infoAbcText)) { // Check for abc
                    if (abcText.selectedText == "")
                        myImpExAbc.write(abcText.text);
                    else
                        myImpExAbc.write(abcText.selectedText);
                    var myImpExAbcPath = myImpExAbc.source;
                    myImpExAbcPath = "\"" + getLocalPath(myImpExAbcPath) + "\"";
                    var scoreLineBreak;
                    if (lbCheckBox.checked)
                        scoreLineBreak = " ";
                    else
                        scoreLineBreak = " -b ";                   
                    console.log(pathAbc2Xml + scoreLineBreak + myImpExAbcPath);
                    proc.start(pathAbc2Xml + scoreLineBreak + "--meta W:rights " + myImpExAbcPath);
                    var val = proc.waitForFinished(5000);
                    if (val) {
                        myFile.write(proc.readAllStandardOutput());
                        readScore(myFile.source);
                        myFile.write("");
                        Qt.quit();
                        }
                    }
                else {
                    infoText.text = qsTr("No abc to import.")
                    userInfo.visible = true;                   
                    }
                }
            else {
                if (pathAbc2Xml == "")
                    infoText.text = qsTr("This function needs abc2xml.\nCopy file into abc_ImpEx folder\nor enter path into abc_ImpEx.ini.");     
                else
                    infoText.text = qsTr("Python not found!.\nPlease check your installation and\nenvironment variables.");
                userInfo.visible = true;
                }
            }
        }
        
    Button {
        id : buttonCancel
        text: qsTranslate("QPlatformTheme", "Cancel") //qsTr("Cancel")
        anchors.bottom: window.bottom
        anchors.horizontalCenter: window.horizontalCenter
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        anchors.rightMargin: 5
        onClicked: {
            Qt.quit();
            }
        }

    Button { // Export Xml into temp Abc and display result
        id : buttonExport
        text: qsTranslate("QPlatformTheme", "Export") //qsTr("Export")
        anchors.bottom: window.bottom
        anchors.right: buttonSaveFile.left
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        anchors.rightMargin: 5
        onClicked: {
            if (curScore) { // Check for score
                if (pathXml2Abc !== "" && pathXml2Abc.startsWith("python0") == false) { // Check for converter und python
                    writeScore(curScore, myExportXml.source, "xml");
                    var myExportXmlPath = myExportXml.source;
                    myExportXmlPath = "\"" + getLocalPath(myExportXmlPath) + "\"";
                    var scoreLineBreak;
                    if (lbCheckBox.checked == true)
                        scoreLineBreak = " ";
                    else
                        scoreLineBreak = " -x ";
                    proc.start(pathXml2Abc + scoreLineBreak + myExportXmlPath);  
                    var val = proc.waitForFinished(5000);
                    if (val) {
                        myFile.write(proc.readAllStandardOutput());
                        abcText.text = myFile.read();
                        }
                    }
                else {
                    if (pathXml2Abc == "")
                        infoText.text = qsTr("This function needs xml2abc.\nCopy file into abc_ImpEx folder\nor enter path into abc_ImpEx.ini.");
                    else
                        infoText.text = qsTr("Python not found!.\nPlease check your installation and\nenvironment variables.");
                    userInfo.visible = true;
                    }
                }
            else {
                infoText.text = qsTr("No score to export.");
                userInfo.visible = true; 
                }
            }
        }
        
    Button { // Save Abc File
        id : buttonSaveFile
        text: qsTranslate("QPlatformTheme", "Save") //qsTr("Save...")
        anchors.bottom: window.bottom
        anchors.right: abcText.right
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        anchors.rightMargin: 10
        onClicked: {
            if (abcText.text !== "" && abcText.text !== qsTr(installAbcText).arg(pathImpEx2) && abcText.text !== qsTr(infoAbcText)) {
                saveDialog.open();
                //Qt.quit();
                }
            else {        
                infoText.text = qsTr("No abc to save.")
                userInfo.visible = true;
                }
            }
        }
    
    function getLocalPath(path) { // Remove "file://" from paths and third "/" from  paths in Windows
        path = path.replace(/^(file:\/{2})/,"");
        if (Qt.platform.os == "windows") path = path.replace(/^\//,"");            
        return path;
    }        
    
    function prepConvPath(path) { // Clean and prepare paths for running converters 
        path = getLocalPath(path);
        if (path.indexOf('"') == -1) path = "\"" + path  + "\"";
        if (path.indexOf(".py") > -1) {
            var python = whatPython();
            path = "python" + python + " -X utf8 " + path;
            }
        return path;
        }
    
    function readIniFile() { // Search ini entries for converters     
        var iniLines = iniFile.read().split("\n");
        var iniEntries = [];
        var path = "";
        for (var l=0; l<iniLines.length; l++) {
            if (iniLines[l] !== "" && iniLines[l] !== undefined) {
                if (iniLines[l].indexOf("abc2xml") == 0 || iniLines[l].indexOf("xml2abc") == 0) {
                    iniEntries = iniLines[l].split("=");
                    path = iniEntries[1].trim();
                    if (path.length > 7) {
                        path = prepConvPath(path);
                        if (iniEntries[0].indexOf("abc2xml") > -1)
                            if (pathAbc2Xml == "") pathAbc2Xml = path;
                        if (iniEntries[0].indexOf("xml2abc") > -1)
                            if (pathXml2Abc == "") pathXml2Abc = path;
                        }
                    }
                }
            }    
        }
        
    function whatPython() { // Identify Python call 
        var pcalls = ["3", "", "2"];
        var python;
        for (var i=0; i<3; i++) { // Check which one works
            proc.start("python" + pcalls[i] + " -V");
            var val = proc.waitForFinished(500);
            if (val) {
                python = String(proc.readAllStandardOutput());            
                if (python.startsWith("Python")) {
                    return pcalls[i];
                    break;
                    }
                }
            else {
                if (i == 2) return "0";
                }
            }
        }
    }