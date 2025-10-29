namespace Microsoft.SubscriptionBilling;

using Microsoft.Sales.Document;

tableextension 8053 "Sales Header" extends "Sales Header"
{
    fields
    {
        field(8051; "Recurring Billing"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Recurring Billing';
            ToolTip = 'Specifies whether the document was created by Subscription Billing.';
            Editable = false;
        }
        field(8052; "Sub. Contract Detail Overview"; Enum "Contract Detail Overview")
        {
            Caption = 'Subscription Contract Detail Overview';
            ToolTip = 'Specifies whether to automatically print the billing details for this document. This is only relevant if you are using Subscription Billing functionalities.';
            DataClassification = CustomerContent;
        }
        field(8053; "Auto Contract Billing"; Boolean)
        {
            Caption = 'Auto Contract Billing';
            ToolTip = 'Specifies whether the Document has been created by an auto billing template.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    local procedure GetLastLineNo(): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        if SalesLine.FindLast() then
            exit(SalesLine."Line No.");
    end;

    internal procedure GetNextLineNo(): Integer
    begin
        exit(GetLastLineNo() + 10000);
    end;

    internal procedure HasOnlyContractRenewalLines(): Boolean
    var
        SalesLine: Record "Sales Line";
        HasContractRenewalLines: Boolean;
    begin
        SalesLine.ReadIsolation(ReadIsolation::ReadUncommitted);
        SalesLine.SetRange("Document Type", Rec."Document Type");
        SalesLine.SetRange("Document No.", Rec."No.");
        SalesLine.SetFilter(Type, '<>%1', "Sales Line Type"::" ");
        if SalesLine.FindSet() then begin
            HasContractRenewalLines := true;
            repeat
                if not SalesLine.IsContractRenewal() then
                    HasContractRenewalLines := false;
            until (SalesLine.Next() = 0) or (HasContractRenewalLines = false);
        end;
        exit(HasContractRenewalLines);
    end;
}