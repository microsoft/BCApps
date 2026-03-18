// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

table 9080 "Error Handling Parameters"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Journal Template Name"; Code[10])
        {
            DataClassification = SystemMetadata;
        }
        field(3; "Journal Batch Name"; Code[10])
        {
            DataClassification = SystemMetadata;
        }
        field(4; "Document No."; Code[20])
        {
            DataClassification = SystemMetadata;
        }
        field(5; "Previous Document No."; Code[20])
        {
            DataClassification = SystemMetadata;
        }
        field(6; "Posting Date"; Date)
        {
            DataClassification = SystemMetadata;
        }
        field(7; "Previous Posting Date"; Date)
        {
            DataClassification = SystemMetadata;
        }
        field(10; "Full Batch Check"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(11; "Line Modified"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(12; "Line No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(13; "Previous Line No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(14; "Sales Document Type"; Enum "Sales Document Type")
        {
            DataClassification = SystemMetadata;
        }
        field(15; "Purchase Document Type"; Enum "Purchase Document Type")
        {
            DataClassification = SystemMetadata;
        }
        field(20; "Full Document Check"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure IsGenJnlDocumentChanged(): Boolean
    begin
        exit(("Document No." <> "Previous Document No.") or ("Posting Date" <> "Previous Posting Date"));
    end;

    procedure FromArgs(Args: Dictionary of [Text, Text])
    begin
        "Journal Template Name" := CopyStr(Args.Get(FieldName("Journal Template Name")), 1, MaxStrLen("Journal Template Name"));
        "Journal Batch Name" := CopyStr(Args.Get(FieldName("Journal Batch Name")), 1, MaxStrLen("Journal Batch Name"));
        "Line No." := GetIntegerParameterValue(Args, FieldName("Line No."));
        "Previous Line No." := GetIntegerParameterValue(Args, FieldName("Previous Line No."));
        "Line Modified" := GetBooleanParameterValue(Args, FieldName("Line Modified"));
        "Document No." := CopyStr(Args.Get(FieldName("Document No.")), 1, MaxStrLen("Document No."));
        "Posting Date" := GetDateParameterValue(Args, FieldName("Posting Date"));
        "Previous Document No." := CopyStr(Args.Get(FieldName("Previous Document No.")), 1, MaxStrLen("Previous Document No."));
        "Previous Posting Date" := GetDateParameterValue(Args, FieldName("Previous Posting Date"));
        "Full Batch Check" := GetBooleanParameterValue(Args, FieldName("Full Batch Check"));
        "Sales Document Type" := GetSalesDocTypeParameterValue(Args, FieldName("Sales Document Type"));
        "Purchase Document Type" := GetPurchaseDocTypeParameterValue(Args, FieldName("Purchase Document Type"));
        "Full Document Check" := GetBooleanParameterValue(Args, FieldName("Full Document Check"));

        OnAfterFromArgs(Rec, Args);
    end;

    local procedure GetBooleanParameterValue(Args: Dictionary of [Text, Text]; ParameterName: Text) ParameterValue: Boolean
    var
        ParamValueAsText: Text;
    begin
        ParamValueAsText := Args.Get(ParameterName);
        Evaluate(ParameterValue, ParamValueAsText);
    end;

    local procedure GetDateParameterValue(Args: Dictionary of [Text, Text]; ParameterName: Text) ParameterValue: Date
    var
        ParamValueAsText: Text;
    begin
        ParamValueAsText := Args.Get(ParameterName);
        Evaluate(ParameterValue, ParamValueAsText);
    end;

    local procedure GetIntegerParameterValue(Args: Dictionary of [Text, Text]; ParameterName: Text) ParameterValue: Integer
    var
        ParamValueAsText: Text;
    begin
        ParamValueAsText := Args.Get(ParameterName);
        Evaluate(ParameterValue, ParamValueAsText);
    end;

    local procedure GetSalesDocTypeParameterValue(Args: Dictionary of [Text, Text]; ParameterName: Text) SalesDocType: Enum "Sales Document Type"
    var
        ParamValueAsText: Text;
    begin
        ParamValueAsText := Args.Get(ParameterName);
        Evaluate(SalesDocType, ParamValueAsText);
    end;

    local procedure GetPurchaseDocTypeParameterValue(Args: Dictionary of [Text, Text]; ParameterName: Text) PurchaseDocType: Enum "Purchase Document Type"
    var
        ParamValueAsText: Text;
    begin
        ParamValueAsText := Args.Get(ParameterName);
        Evaluate(PurchaseDocType, ParamValueAsText);
    end;

    procedure ToArgs(var Args: Dictionary of [Text, Text])
    begin
        Args.Add(FieldName("Journal Template Name"), "Journal Template Name");
        Args.Add(FieldName("Journal Batch Name"), "Journal Batch Name");
        Args.Add(FieldName("Line Modified"), Format("Line Modified"));
        Args.Add(FieldName("Line No."), Format("Line No."));
        Args.Add(FieldName("Previous Line No."), Format("Previous Line No."));
        Args.Add(FieldName("Document No."), "Document No.");
        Args.Add(FieldName("Posting Date"), Format("Posting Date"));
        Args.Add(FieldName("Previous Document No."), "Previous Document No.");
        Args.Add(FieldName("Previous Posting Date"), Format("Previous Posting Date"));
        Args.Add(FieldName("Full Batch Check"), Format("Full Batch Check"));
        Args.Add(FieldName("Sales Document Type"), Format("Sales Document Type"));
        Args.Add(FieldName("Purchase Document Type"), Format("Purchase Document Type"));
        Args.Add(FieldName("Full Document Check"), Format("Full Document Check"));

        OnAfterToArgs(Rec, Args);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromArgs(var ErrorHandlingParameters: Record "Error Handling Parameters"; var Args: Dictionary of [Text, Text])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterToArgs(var ErrorHandlingParameters: Record "Error Handling Parameters"; var Args: Dictionary of [Text, Text])
    begin
    end;
}
