namespace Microsoft.SubscriptionBilling;

using Microsoft.CRM.Team;
using System.Security.User;

table 8022 "Contract Billing Err. Log"
{
    Caption = 'Contract Billing Error Log';
    DataClassification = CustomerContent;
    DrillDownPageId = "Contract Billing Err. Log";
    LookupPageId = "Contract Billing Err. Log";
    Permissions =
        tabledata "Contract Billing Err. Log" = rmid,
        tabledata "Billing Line" = rm;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the unique entry number for the error log record.';
            AutoIncrement = true;
        }
        field(3; "Billing Template Code"; Code[20])
        {
            Caption = 'Billing Template Code';
            ToolTip = 'Specifies the billing template code that was being processed when the error occurred.';
            TableRelation = "Billing Template".Code;
        }
        field(4; "Error Text"; Text[250])
        {
            Caption = 'Error Text';
            ToolTip = 'Specifies the error message that occurred during the auto contract billing process.';
        }
        field(5; "Subscription"; Code[20])
        {
            Caption = 'Subscription';
            ToolTip = 'Specifies the subscription number that was being processed when the error occurred.';
            TableRelation = "Subscription Header"."No.";
        }
        field(6; "Subscription Entry No."; Integer)
        {
            Caption = 'Subscription Entry No.';
            ToolTip = 'Specifies the subscription line entry number that was being processed when the error occurred.';
            TableRelation = "Subscription Line"."Entry No.";
        }
        field(7; "Subscription Contract No."; Code[20])
        {
            Caption = 'Subscription Contract No.';
            ToolTip = 'Specifies the subscription contract number that was being processed when the error occurred.';
            TableRelation = "Customer Subscription Contract"."No.";
        }
        field(8; "Contract Line No."; Integer)
        {
            Caption = 'Contract Line No.';
            ToolTip = 'Specifies the contract line number that was being processed when the error occurred.';
            TableRelation = "Cust. Sub. Contract Line"."Line No." where("Subscription Contract No." = field("Subscription Contract No."));
        }
        field(9; "Contract Type"; Code[20])
        {
            Caption = 'Contract Type';
            ToolTip = 'Specifies the contract type that was being processed when the error occurred.';
            TableRelation = "Subscription Contract Type".Code;
        }
        field(10; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            ToolTip = 'Specifies the user ID assigned to handle this error.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup"."User ID";
        }
        field(11; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            ToolTip = 'Specifies the salesperson code associated with the contract that had an error.';
            TableRelation = "Salesperson/Purchaser";
        }
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    local procedure InitRecord()
    begin
        Rec.Init();
        Rec."Entry No." := 0;
    end;

    internal procedure InsertUnspecificLog(ErrorText: Text[250])
    begin
        InitRecord();
        Rec."Error Text" := ErrorText;
        Rec.Insert();
    end;

    internal procedure InsertLogFromBillingTemplate(BillingTemplateCode: Code[20]; ErrorText: Text[250])
    begin
        InitRecord();
        Rec."Billing Template Code" := BillingTemplateCode;
        Rec."Error Text" := ErrorText;
        Rec.Insert();
    end;

    internal procedure InsertLogFromSubscriptionLine(BillingTemplateCode: Code[20]; SubscriptionLine: Record "Subscription Line"; ErrorText: Text[250])
    var
        CustomerSubscriptionContract: Record "Customer Subscription Contract";
    begin
        InitRecord();
        Rec."Billing Template Code" := BillingTemplateCode;
        Rec."Error Text" := ErrorText;
        Rec."Subscription" := SubscriptionLine."Subscription Header No.";
        Rec."Subscription Entry No." := SubscriptionLine."Entry No.";
        Rec."Subscription Contract No." := SubscriptionLine."Subscription Contract No.";
        Rec."Contract Line No." := SubscriptionLine."Subscription Contract Line No.";
        case SubscriptionLine.Partner of
            SubscriptionLine.Partner::Customer:
                if CustomerSubscriptionContract.Get(SubscriptionLine."Subscription Contract No.") then begin
                    Rec."Contract Type" := CustomerSubscriptionContract."Contract Type";
                    Rec."Assigned User ID" := CustomerSubscriptionContract."Assigned User ID";
                    Rec."Salesperson Code" := CustomerSubscriptionContract."Salesperson Code";
                end;
        end;
        Rec.Insert();
    end;

    procedure DeleteEntries(DaysOld: Integer)
    var
        BillingLine: Record "Billing Line";
        Window: Dialog;
        ConfirmDeletingAllEntriesQst: Label 'Are you sure that you want to delete all entries?';
        ConfirmDeletingEntriesQst: Label 'Are you sure that you want to delete log entries older than %1 days?', Comment = '%1 = Days Old';
        DeletingMsg: Label 'Deleting Entries...';
        DeletedMsg: Label 'Entries have been deleted.';
    begin
        if DaysOld = 0 then begin
            if not Confirm(ConfirmDeletingAllEntriesQst) then
                exit;
        end else
            if not Confirm(StrSubstNo(ConfirmDeletingEntriesQst, DaysOld)) then
                exit;

        Window.Open(DeletingMsg);
        Rec.Reset();
        if DaysOld = 0 then begin
            BillingLine.ModifyAll("Billing Error Log Entry No.", 0);
            Rec.DeleteAll();
        end else begin
            Rec.SetFilter(SystemCreatedAt, '<=%1', CreateDateTime(Today - DaysOld, Time));
            if Rec.FindSet() then
                repeat
                    BillingLine.SetRange("Billing Error Log Entry No.", Rec."Entry No.");
                    BillingLine.ModifyAll("Billing Error Log Entry No.", 0);
                until Rec.Next() = 0;
            Rec.DeleteAll();
        end;

        Window.Close();
        Message(DeletedMsg);
    end;
}
