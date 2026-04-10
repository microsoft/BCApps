namespace System.Automation;

using System;
using System.Utilities;
using System.Xml;

codeunit 1560 "Workflow Imp. / Exp. Mgt"
{

    trigger OnRun()
    begin
    end;

    var
        MoreThanOneWorkflowImportErr: Label 'You cannot import more than one workflow.';

    procedure GetWorkflowCodeListFromXml(TempBlob: Codeunit "Temp Blob") WorkflowCodes: Text
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        XmlNodeList: DotNet XmlNodeList;
        XmlNode: DotNet XmlNode;
        InStream: InStream;
    begin
        TempBlob.CreateInStream(InStream);
        XMLDOMManagement.LoadXMLNodeFromInStream(InStream, XmlNode);

        XMLDOMManagement.FindNodes(XmlNode, '/Root/Workflow', XmlNodeList);

        foreach XmlNode in XmlNodeList do
            if WorkflowCodes = '' then
                WorkflowCodes := XMLDOMManagement.GetAttributeValue(XmlNode, 'Code')
            else
                WorkflowCodes := WorkflowCodes + ',' + XMLDOMManagement.GetAttributeValue(XmlNode, 'Code');
    end;

    [Scope('OnPrem')]
    procedure ReplaceWorkflow(var Workflow: Record Workflow; var TempBlob: Codeunit "Temp Blob")
    var
        FromWorkflow: Record Workflow;
        CopyWorkflow: Report "Copy Workflow";
        NewWorkflowCodes: Text;
        TempWorkflowCode: Text[20];
    begin
        NewWorkflowCodes := GetWorkflowCodeListFromXml(TempBlob);
        if TrySelectStr(2, NewWorkflowCodes, TempWorkflowCode) then
            Error(MoreThanOneWorkflowImportErr);

        FromWorkflow.Init();
        FromWorkflow.Code := CopyStr(Format(CreateGuid()), 1, MaxStrLen(Workflow.Code));
        FromWorkflow.ImportFromBlob(TempBlob);

        CopyWorkflow.InitCopyWorkflow(FromWorkflow, Workflow);
        CopyWorkflow.UseRequestPage(false);
        CopyWorkflow.Run();

        FromWorkflow.Delete(true);
    end;

    [TryFunction]
    local procedure TrySelectStr(Index: Integer; InputString: Text; var SelectedString: Text[20])
    begin
        SelectedString := SelectStr(Index, InputString);
    end;
}

