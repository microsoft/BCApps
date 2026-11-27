codeunit 101899 "Create Demo Data from Config"
{

    trigger OnRun()
    begin
        if ErrorMsgMgt.IsActive() then
            CreateDemoData()
        else
            CreateDemoDataLogToFile(LogFileNameTxt);
    end;

    var
        ErrorMsgMgt: codeunit "Error Message Management";
        LogFileNameTxt: label 'CreateDemoData.log', Locked = true;

    local procedure CreateDemoData()
    var
        DemoDataSetup: Record "Demo Data Setup";
    begin
        SetupDemonstrationData(DemoDataSetup);
        SeedEntryTables();
        CODEUNIT.Run(CODEUNIT::"Create Demonstration Data");
        CleanUp();
        UnSeedEntryTables();
    end;

    local procedure CreateDemoDataLogToFile(LogFileName: Text) Success: Boolean;
    var
        ErrorMsgHandler: Codeunit "Error Message Handler";
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorCallStack: Text;
        ErrorText: Text;
    begin
        ErrorMsgMgt.Activate(ErrorMsgHandler);
        ErrorMsgMgt.PushContext(ErrorContextElement, Database::"Demo Data Setup", 0, 'COD101899 "Create Demo Data from Config"');
        Success := Codeunit.Run(Codeunit::"Create Demo Data from Config");
        if not Success then begin
            ErrorCallStack := GetLastErrorCallStack();
            ErrorText := GetLastErrorText();
        end;
        // WriteMessagesToFile() re-throws the last error, 
        // but we have to re-throw it from cod101899 context to be handled by NavRTC_Call in build scripts
        ErrorMsgHandler.WriteMessagesToFile(LogFileName, not Success);
        if not Success then
            error('%1 %2', ErrorText, ErrorCallStack);
    end;

    procedure SetupDemonstrationData(var DemoDataSetup: Record "Demo Data Setup")
    var
        GLSetup: Record "General Ledger Setup";
        DemoDataTool: Page "Demonstration Data Tool";
    begin
        if not GLSetup.Get() then
            CODEUNIT.Run(CODEUNIT::"Company-Initialize");
        if DemoDataSetup.Get() then
            DemoDataSetup.Delete();
        ImportDemoDataConfig();
        DemoDataSetup.Get();
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Evaluation then
            DemoDataSetup."Starting Year" := Date2DMY(Today, 3) - 1
        else
            DemoDataSetup."Starting Year" := Date2DMY(Today, 3) + 1;
        DemoDataSetup."Working Date" := DMY2Date(1, 1, DemoDataSetup."Starting Year");
        DemoDataSetup."Progress Window Design" := DemoDataTool.ProgressWindowDesign();
        DemoDataSetup."LCY an EMU Currency" := (DemoDataSetup."Currency Code" = 'EUR');
        DemoDataSetup."Remove Country Prefix" := true;
        DemoDataSetup.SetTaxRates();
        DemoDataSetup.Modify(true);
        UpdateDomains(DemoDataSetup);
    end;

    procedure CleanUp()
    var
        DemoDataSetup: Record "Demo Data Setup";
    begin
        DemoDataSetup.DeleteAll();
    end;

    procedure ImportDemoDataConfig()
    var
        DemoDataConfiguration: XMLport "Demo Data Configuration";
        ConfigFile: File;
        ConfigStream: InStream;
        CurrentLanguage: Integer;
    begin
        CurrentLanguage := GlobalLanguage;
        if DemoDataConfiguration.ConfigLanguageID() <> CurrentLanguage then
            GlobalLanguage(DemoDataConfiguration.ConfigLanguageID());

        ConfigFile.Open(DemoDataConfiguration.ConfigFileName(false));
        ConfigFile.CreateInStream(ConfigStream);
        DemoDataConfiguration.SetSource(ConfigStream);
        DemoDataConfiguration.Import();
        ConfigFile.Close();

        if GlobalLanguage <> CurrentLanguage then
            GlobalLanguage(CurrentLanguage);
    end;

    procedure ExporttDemoDataConfig()
    var
        DemoDataConfiguration: XMLport "Demo Data Configuration";
        ConfigFile: File;
        ConfigStream: OutStream;
        CurrentLanguage: Integer;
    begin
        CurrentLanguage := GlobalLanguage;
        if DemoDataConfiguration.ConfigLanguageID() <> CurrentLanguage then
            GlobalLanguage(DemoDataConfiguration.ConfigLanguageID());

        ConfigFile.Create(DemoDataConfiguration.ConfigFileName(false));
        ConfigFile.CreateOutStream(ConfigStream);
        DemoDataConfiguration.SetDestination(ConfigStream);
        DemoDataConfiguration.Export();
        ConfigFile.Close();

        if GlobalLanguage <> CurrentLanguage then
            GlobalLanguage(CurrentLanguage);
    end;

    local procedure UpdateDomains(var DemoDataSetup: Record "Demo Data Setup")
    begin
        if DemoDataSetup."Data Type" <> DemoDataSetup."Data Type"::Extended then begin
            DemoDataSetup.SelectDomains(false);
            DemoDataSetup."Skip sequence of actions" := true;
            DemoDataSetup."Adjust for Payment Discount" := false;
            DemoDataSetup.Modify();
        end;
    end;

    local procedure SeedEntryTables()
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        DetailedCustledgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedVendledgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        InitEntryTableValues(GLEntry."Entry No.", GLEntry."Posting Date");
        if GLEntry.Insert() then;
        InitEntryTableValues(VATEntry."Entry No.", VATEntry."Posting Date");
        VATEntry."VAT Bus. Posting Group" := CopyStr(Format(CreateGuid(), 2), 1, MaxStrLen(VATEntry."VAT Bus. Posting Group")); // to avoid the 'isempty' check in VATPosting Setup
        VATEntry."VAT Prod. Posting Group" := CopyStr(Format(CreateGuid(), 2), 1, MaxStrLen(VATEntry."VAT Bus. Posting Group"));
        if VATEntry.Insert() then;
        InitEntryTableValues(ItemLedgerEntry."Entry No.", ItemLedgerEntry."Posting Date");
        if ItemLedgerEntry.Insert() then;
        InitEntryTableValues(ValueEntry."Entry No.", ValueEntry."Posting Date");
        if ValueEntry.Insert() then;
        InitEntryTableValues(DetailedCustledgEntry."Entry No.", DetailedCustledgEntry."Posting Date");
        if DetailedCustledgEntry.Insert() then;
        InitEntryTableValues(DetailedVendledgEntry."Entry No.", DetailedVendledgEntry."Posting Date");
        if DetailedVendledgEntry.Insert() then;
    end;

    local procedure InitEntryTableValues(var EntryNo: BigInteger; var PostingDate: Date)
    begin
        EntryNo := 5000000000000L;
        PostingDate := Today();
    end;

    local procedure UnSeedEntryTables()
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        DetailedCustledgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedVendledgEntry: Record "Detailed Vendor Ledg. Entry";
        Seed: BigInteger;
    begin
        Seed := 5000000000000L;
        if GLEntry.Get(Seed) then
            if GLEntry.Delete() then;
        if VATEntry.Get(Seed) then
            if VATEntry.Delete() then;
        if ItemLedgerEntry.Get(Seed) then
            if ItemLedgerEntry.Delete() then;
        if ValueEntry.Get(Seed) then
            if ValueEntry.Delete() then;
        if DetailedCustledgEntry.Get(Seed) then
            if DetailedCustledgEntry.Delete() then;
        if DetailedVendledgEntry.Get(Seed) then
            if DetailedVendledgEntry.Delete() then;
    end;
}

