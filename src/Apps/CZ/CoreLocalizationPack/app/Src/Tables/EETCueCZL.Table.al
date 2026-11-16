// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

table 11725 "EET Cue CZL"
{
    Caption = 'EET Cue';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(10; "Sent Entries"; Integer)
        {
            CalcFormula = count("EET Entry CZL" where(Status = const(Sent), "Created At" = field("Created At Filter")));
            Caption = 'Sent';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of EET entries created in the filtered period that have been sent to the EET service and the response has not been processed yet.';
        }
        field(11; "Successful Entries"; Integer)
        {
            CalcFormula = count("EET Entry CZL" where(Status = const(Success), "Created At" = field("Created At Filter")));
            Caption = 'Successfully Sent';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of EET entries created in the filtered period that have been successfully registered by the EET service.';
        }
        field(12; "Entries with Warnings"; Integer)
        {
            CalcFormula = count("EET Entry CZL" where(Status = const("Success with Warnings"), "Created At" = field("Created At Filter")));
            Caption = 'Successfully Sent with Warnings';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of EET entries created in the filtered period that have been registered by the EET service, but the service returned a warning.';
        }
        field(13; "Pending Entries"; Integer)
        {
            CalcFormula = count("EET Entry CZL" where(Status = const("Send Pending"), "Created At" = field("Created At Filter")));
            Caption = 'Waiting to Send';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of EET entries created in the filtered period that are waiting to be sent to the EET service.';
        }
        field(14; "Canceled Entries"; Integer)
        {
            CalcFormula = count("EET Entry CZL" where("Canceled By Entry No." = filter(<> 0), "Created At" = field("Created At Filter")));
            Caption = 'Canceled';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of EET entries created in the filtered period that have been canceled by another EET entry.';
        }
        field(15; "Failed Entries"; Integer)
        {
            CalcFormula = count("EET Entry CZL" where(Status = const(Failure), "Created At" = field("Created At Filter")));
            Caption = 'Communication Error';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of EET entries created in the filtered period for which the communication with the EET service failed.';
        }
#pragma warning disable AA0232
        field(20; "Registered Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("EET Entry CZL"."Total Sales Amount" where(Status = const(Success)));
            Caption = 'Total Registered';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the total sales amount of EET entries that have been successfully registered by the EET service.';
        }
        field(21; "Pending Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("EET Entry CZL"."Total Sales Amount" where(Status = const("Send Pending")));
            Caption = 'Total Waiting for Registration';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the total sales amount of EET entries that are waiting to be sent to the EET service or that have been registered with a warning.';
        }
        field(22; "Canceled Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("EET Entry CZL"."Total Sales Amount" where("Canceled By Entry No." = filter(<> 0)));
            Caption = 'Total Canceled';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the total sales amount of EET entries that have been canceled by another EET entry.';
        }
        field(23; "Failed Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("EET Entry CZL"."Total Sales Amount" where(Status = const(Failure)));
            Caption = 'Total Incorrectly Registered';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the total sales amount of EET entries for which the communication with the EET service failed.';
        }
        field(30; "Created At Filter"; DateTime)
        {
            Caption = 'Created At Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
#pragma warning restore AA0232
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }
}
