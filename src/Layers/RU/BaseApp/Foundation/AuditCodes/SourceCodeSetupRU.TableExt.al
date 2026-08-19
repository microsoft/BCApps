// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.AuditCodes;

#pragma warning disable AS0125
tableextension 12401 SourceCodeSetupRU extends "Source Code Setup"
{
    Caption = 'Source Code Setup';

    fields
    {
        field(12400; "Advance Statements"; Code[10])
        {
            Caption = 'Advance Statements';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(12401; "Deferred VAT Settlement"; Code[10])
        {
            Caption = 'Deferred VAT Settlement';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(12402; "Deferred Expenses"; Code[10])
        {
            Caption = 'Deferred Expenses';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(12403; "Customer Prepayments"; Code[10])
        {
            Caption = 'Customer Prepayments';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(12404; "Vendor Prepayments"; Code[10])
        {
            Caption = 'Vendor Prepayments';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(12405; "Bank Payments"; Code[10])
        {
            Caption = 'Bank Payments';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(12406; "Bank Reconciliations"; Code[10])
        {
            Caption = 'Bank Reconciliations';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(12407; "Cash Order Payments"; Code[10])
        {
            Caption = 'Cash Order Payments';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(12408; "VAT Reinstatement"; Code[10])
        {
            Caption = 'VAT Reinstatement';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(12409; "VAT for Customer Adjustment"; Code[10])
        {
            Caption = 'VAT for Customer Adjustment';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(12410; "VAT for Vendor Adjustment"; Code[10])
        {
            Caption = 'VAT for Vendor Adjustment';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(12411; "VAT Allocation on Cost"; Code[10])
        {
            Caption = 'VAT Allocation on Cost';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(12470; "FA Release"; Code[10])
        {
            Caption = 'FA Release';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(12471; "FA Movement"; Code[10])
        {
            Caption = 'FA Movement';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(12472; "FA Writeoff"; Code[10])
        {
            Caption = 'FA Writeoff';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(17301; "Tax Difference Journal"; Code[10])
        {
            Caption = 'Tax Difference Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
    }
}