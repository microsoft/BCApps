// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.SpendRequest;

tableextension 7109 "Exp. Spend Req. Detail" extends "Spend Request Detail"
{
    fields
    {
        field(6900; "Type"; Enum "Exp. Spend Req. Line Type")
        {
            Caption = 'Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestRequestStatusOpen();
                if Rec.Type <> Rec.Type::Category then
                    Rec."Expense Category Code" := '';
            end;
        }
        field(6901; "Expense Category Code"; Code[20])
        {
            Caption = 'Expense Category';
            DataClassification = CustomerContent;
            TableRelation = "Expense Category".Code where(Inactive = const(false));

            trigger OnValidate()
            begin
                TestRequestStatusOpen();
                if (Rec."Expense Category Code" <> '') and (Rec.Type <> Rec.Type::Category) then
                    Error(CategoryLineOnlyErr, Rec.FieldCaption("Expense Category Code"), Rec.FieldCaption(Type), Rec.Type::Category);
            end;
        }
    }

    var
        CategoryLineOnlyErr: Label 'You can select an %1 only when %2 is %3.', Comment = '%1 = Expense Category field caption, %2 = Type field caption, %3 = Category line type value';

    local procedure TestRequestStatusOpen()
    var
        SpendRequest: Record "Spend Request";
    begin
        if Rec."Spend Request No." = '' then
            exit;

        SpendRequest.SetLoadFields(Status);
        SpendRequest.Get(Rec."Spend Request No.");
        SpendRequest.TestStatusOpen();
    end;
}