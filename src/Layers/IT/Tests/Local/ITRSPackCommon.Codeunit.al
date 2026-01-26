codeunit 148500 "IT RS Pack - Common"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [DEMO] [Common]
    end;

    var
        FatturaPATxt: Label 'FATTURAPA', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaPAElectronicDocumentFormats()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        UsageOption: Option;
    begin
        // [FEATURE] [FatturaPA] [Electronic Document]
        // [SCENARIO 259342] Electronic document format has FatturaPA setup for all Usage options
        for UsageOption := ElectronicDocumentFormat.Usage::"Sales Invoice".AsInteger() to ElectronicDocumentFormat.Usage::"Service Validation".AsInteger() do
            ElectronicDocumentFormat.Get(FatturaPATxt, UsageOption);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaPASalesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [FatturaPA] [Sales]
        // [SCENARIO 259342] Sales Setup has filled "Fattura PA Nos.", "Fattura PA Electronic Format" and "Validate Document On Posting" = FALSE
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.TestField("Fattura PA Nos.");
        SalesReceivablesSetup.TestField("Fattura PA Electronic Format", FatturaPATxt);
        SalesReceivablesSetup.TestField("Validate Document On Posting", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaPAServiceSetup()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        // [FEATURE] [FatturaPA] [Service]
        // [SCENARIO 259342] Service Setup has "Validate Document On Posting" = FALSE
        ServiceMgtSetup.Get();
        ServiceMgtSetup.TestField("Validate Document On Posting", false);
    end;
}

