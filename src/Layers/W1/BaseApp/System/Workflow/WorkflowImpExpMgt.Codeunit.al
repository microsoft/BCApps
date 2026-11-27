namespace System.Automation;

using System.Utilities;

codeunit 1560 "Workflow Imp. / Exp. Mgt"
{

    trigger OnRun()
    begin
    end;

    var
        MoreThanOneWorkflowImportErr: Label 'You cannot import more than one workflow.';

    procedure GetWorkflowCodeListFromXml(TempBlob: Codeunit "Temp Blob") WorkflowCodes: Text
    var
        WorkflowXmlDocument: XmlDocument;
        WorkflowXmlNodeList: XmlNodeList;
        WorkflowXmlNode: XmlNode;
        CodeXmlAttribute: XmlAttribute;
        WorkflowCode: Text;
        InStream: InStream;
    begin
        TempBlob.CreateInStream(InStream);
        XmlDocument.ReadFrom(InStream, WorkflowXmlDocument);

        WorkflowXmlDocument.SelectNodes('/Root/Workflow', WorkflowXmlNodeList);

        foreach WorkflowXmlNode in WorkflowXmlNodeList do begin
            WorkflowCode := '';
            if WorkflowXmlNode.AsXmlElement().Attributes().Get('Code', CodeXmlAttribute) then
                WorkflowCode := CodeXmlAttribute.Value();
            if WorkflowCodes = '' then
                WorkflowCodes := WorkflowCode
            else
                WorkflowCodes := WorkflowCodes + ',' + WorkflowCode;
        end;
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

