namespace Microsoft.SubscriptionBilling;

using System.Security.User;
using System.Threading;

table 8060 "Billing Template"
{
    DataClassification = CustomerContent;
    Caption = 'Billing Template';
    LookupPageId = "Billing Templates";
    DrillDownPageId = "Billing Templates";

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
            trigger OnValidate()
            begin
                SubBillingBackgroundJobs.HandleAutomatedBillingJob(Rec);
            end;
        }
        field(3; Partner; Enum "Service Partner")
        {
            Caption = 'Partner';

            trigger OnValidate()
            begin
                if Partner = Partner::Vendor then
                    TestField(Automation, Automation::None);
                if Partner <> xRec.Partner then
                    Clear(Filter);
            end;
        }
        field(5; "Billing Date Formula"; DateFormula)
        {
            Caption = 'Billing Date Formula';
        }
        field(6; "Billing to Date Formula"; DateFormula)
        {
            Caption = 'Billing to Date Formula';
        }
        field(7; "My Suggestions Only"; Boolean)
        {
            Caption = 'My Suggestions Only';
        }
        field(9; "Group by"; Enum "Contract Billing Grouping")
        {
            Caption = 'Group by';
            InitValue = Contract;
        }
        field(10; "Filter"; Blob)
        {
            Caption = 'Filter';
        }
        field(11; "Posting Date Formula"; DateFormula)
        {
            Caption = 'Posting Date Formula';
            ToolTip = 'Specifies the date formula used to calculate the Posting Date. If the field is left empty, the Posting Date is prefilled with workdate, or with today when the process runs automatically.';
        }
        field(12; "Document Date Formula"; DateFormula)
        {
            Caption = 'Document Date Formula';
            ToolTip = 'Specifies the date formula used to calculate the Document Date. If the field is left empty, the Document Date is prefilled with workdate, or with today when the process runs automatically.';
        }
        field(13; "Customer Document per"; Enum "Customer Rec. Billing Grouping")
        {
            Caption = 'Customer Document per';
            ToolTip = 'Specifies how the Billing lines for customers are grouped in sales documents.';
            trigger OnValidate()
            begin
                TestField(Partner, Partner::Customer);
            end;
        }
        field(15; Automation; Enum "Sub. Billing Automation")
        {
            Caption = 'Automation';
            ToolTip = 'Specifies if the billing process is automated.';
            trigger OnValidate()
            begin
                if not UserSetup.AutoContractBillingAllowed() then
                    Error(AutoContractBillingNotAllowedErr);
                case Automation of
                    Automation::None:
                        "Minutes between runs" := 0;
                    Automation::"Create Billing Proposal and Documents":
                        begin
                            TestField(Partner, Partner::Customer);
                            "My Suggestions Only" := false;
                            "Minutes between runs" := 60;
                        end;
                end;
                SubBillingBackgroundJobs.HandleAutomatedBillingJob(Rec);
            end;
        }
        field(17; "Minutes between runs"; Integer)
        {
            Caption = 'Minutes between runs';
            ToolTip = 'Specifies the frequency, in minutes, for running the automation.';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                TestField(Automation, Automation::"Create Billing Proposal and Documents");
                SubBillingBackgroundJobs.HandleAutomatedBillingJob(Rec);
            end;
        }
        field(18; "Batch Recurrent Job Id"; Guid)
        {
            Caption = 'Batch Recurrent Job Id';
            ToolTip = 'Specifies the ID of the job queue entry that runs the billing process in the background.';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(19; "Batch Rec. Job Description"; Text[250])
        {
            Caption = 'Batch Recurrent Job Description';
            ToolTip = 'Specifies the description of the job queue entry that runs the billing process in the background.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Job Queue Entry".Description where("ID" = field("Batch Recurrent Job Id")));
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }

    trigger OnModify()
    begin
        if Automation <> Automation::None then
            if not UserSetup.AutoContractBillingAllowed() then
                Error(AutoContractBillingNotAllowedErr);
    end;

    trigger OnDelete()
    begin
        if Automation <> Automation::None then
            if not UserSetup.AutoContractBillingAllowed() then
                Error(AutoContractBillingNotAllowedErr);

    end;

    var
        UserSetup: Record "User Setup";
        SubBillingBackgroundJobs: Codeunit "Sub. Billing Background Jobs";
        AutoContractBillingNotAllowedErr: Label 'You cannot change the auto billing templates because you are not set up as an Auto Contract Billing user in the User Setup.';

    internal procedure EditFilter(FieldNumber: Integer): Boolean
    var
        FilterPageBuilder: FilterPageBuilder;
        RRef: RecordRef;
        FilterText: Text;
        DefaultFilterFields: array[10] of Integer;
        i: Integer;
    begin
        case FieldNumber of
            FieldNo(Filter):
                case Rec.Partner of
                    "Service Partner"::Customer:
                        begin
                            AddDefaultFilterFields(DefaultFilterFields, "Service Partner"::Customer);
                            RRef.Open(Database::"Customer Subscription Contract");
                        end;
                    "Service Partner"::Vendor:
                        begin
                            AddDefaultFilterFields(DefaultFilterFields, "Service Partner"::Vendor);
                            RRef.Open(Database::"Vendor Subscription Contract");
                        end;
                end;
        end;

        FilterPageBuilder.AddTable(RRef.Caption, RRef.Number);
        FilterText := ReadFilter(FieldNumber);
        if FilterText <> '' then
            FilterPageBuilder.SetView(RRef.Caption, FilterText);

        for i := 1 to ArrayLen(DefaultFilterFields) do
            if DefaultFilterFields[i] <> 0 then
                FilterPageBuilder.AddFieldNo(RRef.Caption, DefaultFilterFields[i]);

        if FilterPageBuilder.RunModal() then begin
            RRef.SetView(FilterPageBuilder.GetView(RRef.Caption));
            FilterText := RRef.GetView(false);
            WriteFilter(FieldNumber, FilterText);
            exit(true);
        end;
    end;

    internal procedure ReadFilter(FieldNumber: Integer) FilterText: Text
    var
        IStream: InStream;
    begin
        case FieldNumber of
            FieldNo(Filter):
                begin
                    CalcFields(Filter);
                    Filter.CreateInStream(IStream, TextEncoding::UTF8);
                end;
        end;
        IStream.ReadText(FilterText);
    end;

    internal procedure WriteFilter(FieldNumber: Integer; FilterText: Text)
    var
        RRef: RecordRef;
        BlankView: Text;
        OStream: OutStream;
    begin
        case FieldNumber of
            FieldNo(Filter):
                begin
                    Clear(Filter);
                    case Rec.Partner of
                        "Service Partner"::Customer:
                            RRef.Open(Database::"Customer Subscription Contract");
                        "Service Partner"::Vendor:
                            RRef.Open(Database::"Vendor Subscription Contract");
                    end;
                    BlankView := RRef.GetView(false);
                    Filter.CreateOutStream(OStream, TextEncoding::UTF8);
                end;
        end;

        if FilterText <> BlankView then
            OStream.WriteText(FilterText);
        Modify();
    end;

    local procedure AddDefaultFilterFields(var DefaultFilterFields: array[10] of Integer; ServicePartner: Enum "Service Partner")
    var
        CustomerContract: Record "Customer Subscription Contract";
        VendorContract: Record "Vendor Subscription Contract";
    begin
        case ServicePartner of
            "Service Partner"::Customer:
                begin
                    DefaultFilterFields[1] := CustomerContract.FieldNo("Billing Rhythm Filter");
                    DefaultFilterFields[2] := CustomerContract.FieldNo("Assigned User ID");
                    DefaultFilterFields[3] := CustomerContract.FieldNo("Contract Type");
                    DefaultFilterFields[4] := CustomerContract.FieldNo("Salesperson Code");
                end;
            "Service Partner"::Vendor:
                begin
                    DefaultFilterFields[1] := CustomerContract.FieldNo("Billing Rhythm Filter");
                    DefaultFilterFields[2] := CustomerContract.FieldNo("Assigned User ID");
                    DefaultFilterFields[3] := CustomerContract.FieldNo("Contract Type");
                    DefaultFilterFields[4] := VendorContract.FieldNo("Purchaser Code");
                end;
        end;
    end;

    internal procedure IsPartnerCustomer(): Boolean
    begin
        exit(Rec.Partner = Rec.Partner::Customer);
    end;

    internal procedure BillContractsAutomatically()
    var
        BillingLine: Record "Billing Line";
        CreateBillingDocuments: Codeunit "Create Billing Documents";
        BillingProposal: Codeunit "Billing Proposal";
        PostingDate: Date;
        DocumentDate: Date;
        BillingDate: Date;
        BillingToDate: Date;
    begin
        CalculateBillingDates(BillingDate, BillingToDate, true);
        BillingProposal.CreateBillingProposal(Code, BillingDate, BillingToDate, true);
        BillingLine.Reset();
        BillingLine.SetRange("Billing Template Code", Code);
        if not BillingLine.IsEmpty then begin
            CalculateDocumentDates(PostingDate, DocumentDate, true);
            CreateBillingDocuments.SetCustomerRecurringBillingGrouping("Customer Document per");
            CreateBillingDocuments.SetDocumentDataFromRequestPage(DocumentDate, PostingDate, false, false);
            CreateBillingDocuments.SetAutomatedBilling(true);
            CreateBillingDocuments.Run(BillingLine);
        end;
    end;

    internal procedure CalculateBillingDates(var BillingDate: Date; var BillingToDate: Date; BackgroundProcess: Boolean)
    var
        ReferenceDate: Date;
    begin
        if BackgroundProcess then
            ReferenceDate := Today()
        else
            ReferenceDate := WorkDate();

        if Format("Billing Date Formula") <> '' then
            BillingDate := CalcDate("Billing Date Formula", ReferenceDate)
        else
            BillingDate := ReferenceDate;

        if Format("Billing to Date Formula") <> '' then
            BillingToDate := CalcDate("Billing to Date Formula", ReferenceDate)
        else
            BillingToDate := 0D;
    end;

    internal procedure CalculateDocumentDates(var PostingDate: Date; var DocumentDate: Date; BackgroundProcess: Boolean)
    var
        ReferenceDate: Date;
    begin
        if BackgroundProcess then
            ReferenceDate := Today()
        else
            ReferenceDate := WorkDate();

        if Format("Posting Date Formula") <> '' then
            PostingDate := CalcDate("Posting Date Formula", ReferenceDate)
        else
            PostingDate := ReferenceDate;
        if Format("Document Date Formula") <> '' then
            DocumentDate := CalcDate("Document Date Formula", ReferenceDate)
        else
            DocumentDate := ReferenceDate;
    end;

    internal procedure LookupJobEntryQueue()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Get("Batch Recurrent Job Id");
        JobQueueEntry.SetRecFilter();
        Page.Run(0, JobQueueEntry);
    end;

    internal procedure ClearAutomationFields()
    begin
        "Automation" := "Automation"::None;
        Clear("Batch Recurrent Job Id");
        "Minutes between runs" := 0;
    end;
}