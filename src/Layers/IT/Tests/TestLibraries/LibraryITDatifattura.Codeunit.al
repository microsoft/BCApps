codeunit 143005 "Library - IT Datifattura"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";

    [Scope('OnPrem')]
    procedure ExportVATReport(VATReportHeader: Record "VAT Report Header"): Text
    var
        NameValueBuffer: Record "Name/Value Buffer";
        LibraryITDatifattura: Codeunit "Library - IT Datifattura";
        DatifatturaExport: Codeunit "Datifattura Export";
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
    begin
        BindSubscription(LibraryITDatifattura);
        VATReportHeader.SetRecFilter();
        VATReportReleaseReopen.Release(VATReportHeader);
        DatifatturaExport.Run(VATReportHeader);
        UnbindSubscription(LibraryITDatifattura);
        NameValueBuffer.FindLast();
        exit(NameValueBuffer.Value);
    end;

    [Scope('OnPrem')]
    procedure CreateVendor(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Fiscal Code" := '1231592749271424';
        Vendor."VAT Registration No." := '19283749201';
        Vendor.Modify();
    end;

    [Scope('OnPrem')]
    procedure CreateGeneralSetup()
    var
        CompanyInformation: Record "Company Information";
        VATReportSetup: Record "VAT Report Setup";
        Vendor: Record Vendor;
    begin
        if not VATReportSetup.Get() then begin
            VATReportSetup.Init();
            VATReportSetup.Insert(true);
        end;
        VATReportSetup.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
        VATReportSetup.Validate("Intermediary VAT Reg. No.", '19988771002');
        VATReportSetup.Validate("Intermediary CAF Reg. No.", Format(LibraryRandom.RandInt(100)));
        VATReportSetup.Validate("Intermediary Date", CalcDate('<-3M>', Today));
        VATReportSetup.Validate("Modify Submitted Reports", false);
        VATReportSetup.Modify(true);

        CreateVendor(Vendor);

        CompanyInformation.Get();
        CompanyInformation.Validate("Fiscal Code", '19988771001');
        CompanyInformation.Validate("VAT Registration No.", '19988771002');
        CompanyInformation.Validate(Name, 'CRONUS Italia S.p.A.');
        CompanyInformation.Validate(City, 'Rome');
        CompanyInformation.Validate(County, 'AG');
        CompanyInformation.Validate("Industrial Classification", '35.11.00');
        CompanyInformation.Validate("Tax Representative No.", Vendor."No.");
        CompanyInformation.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateGeneralSetupDatifattura()
    var
        CompanyInformation: Record "Company Information";
        CompanyOfficials: Record "Company Officials";
        PostCode: Record "Post Code";
    begin
        CompanyOfficials.Init();
        CompanyOfficials."No." := LibraryUtility.GenerateGUID();
        CompanyOfficials."First Name" :=
          LibraryUtility.GenerateRandomCode(CompanyOfficials.FieldNo("First Name"), DATABASE::"Company Officials");
        CompanyOfficials."Last Name" :=
          LibraryUtility.GenerateRandomCode(CompanyOfficials.FieldNo("Last Name"), DATABASE::"Company Officials");
        CompanyOfficials."Fiscal Code" :=
          LibraryUtility.GenerateRandomCode(CompanyOfficials.FieldNo("Fiscal Code"), DATABASE::"Company Officials");
        CompanyOfficials."Appointment Code" := '01';
        CompanyOfficials."Date of Birth" := CalcDate('<-' + Format(LibraryRandom.RandInt(100)) + 'Y>');
        LibraryERM.CreatePostCode(PostCode);
        CompanyOfficials.Validate("Post Code", PostCode.Code);
        CompanyOfficials.Insert();

        CompanyInformation.Get();
        CompanyInformation.Validate("General Manager No.", CompanyOfficials."No.");
        CompanyInformation.Validate("Tax Representative No.", '');
        CompanyInformation.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SetFilterDatifatturaLines(NewValue: Boolean)
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportSetup.Validate("Filter Datifattura Lines", NewValue);
        VATReportSetup.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Datifattura Export", 'OnBeforeSaveFileOnClient', '', false, false)]
    local procedure SetFileNameOnBeforeSaveFileOnClient(var NewServerFilePath: Text)
    var
        NameValueBuffer: Record "Name/Value Buffer";
        FileManagement: Codeunit "File Management";
    begin
        NameValueBuffer.Name := LibraryUtility.GenerateGUID();
        NameValueBuffer.Value := CopyStr(FileManagement.ServerTempFileName('xml'), 1, MaxStrLen(NameValueBuffer.Value));
        NameValueBuffer.Insert(true);

        NewServerFilePath := NameValueBuffer.Value;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Error Message", 'OnAfterInsertEvent', '', false, false)]
    local procedure ThrowErrorOnAfterInsertEventTableErrorMessage(var Rec: Record "Error Message"; RunTrigger: Boolean)
    begin
        if Rec."Message Type" = Rec."Message Type"::Error then
            Error('%1: <%2> in %3', Rec."Message Type", Rec.Message, Rec."Context Record ID");
    end;
}

