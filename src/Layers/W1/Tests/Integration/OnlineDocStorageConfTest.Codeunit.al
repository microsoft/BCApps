codeunit 139100 "Online Doc. Storage Conf Test"
{
    Permissions = TableData "Document Service" = imd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [INT] [Document Service] [UI]
    end;

    var
        Assert: Codeunit Assert;

    [Normal]
    local procedure InitializeConfig()
    var
        Config: Record "Document Service";
    begin
        Config.DeleteAll();

        Config.Init();
        Config."Service ID" := 'Service ID';
        Config.Description := 'Description';
        Config.Location := 'http://location';
        Config."User Name" := 'User Name';
        Config."Document Repository" := 'Document Repository';
        Config.Folder := 'Folder';
        Config.Insert();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestOnlyOneConfigExists()
    var
        DocServConf: Record "Document Service";
    begin
        InitializeConfig();

        Assert.AreEqual(DocServConf.Count, 1, 'No configuration or more than one entry detected');
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Answer: Boolean)
    begin
        Answer := true;
    end;
}

