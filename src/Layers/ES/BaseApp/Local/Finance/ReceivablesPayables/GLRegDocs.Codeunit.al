// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.GeneralLedger.Ledger;

codeunit 7000001 "G/L Reg.-Docs."
{

    trigger OnRun()
    begin
    end;

    var
        Doc: Record "Cartera Doc.";
        PostedDoc: Record "Posted Cartera Doc.";
        ClosedDoc: Record "Closed Cartera Doc.";

    [Scope('OnPrem')]
    procedure Docs(var GLReg: Record "G/L Register")
    begin
        Doc.SetRange("Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
        PAGE.Run(0, Doc);
    end;

    [Scope('OnPrem')]
    procedure DocsinPostedBGPO(var GLReg: Record "G/L Register")
    begin
        PostedDoc.SetRange("Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
        PAGE.Run(0, PostedDoc);
    end;

    [Scope('OnPrem')]
    procedure ClosedDocs(var GLReg: Record "G/L Register")
    begin
        ClosedDoc.SetRange("Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
        PAGE.Run(0, ClosedDoc);
    end;

    [Scope('OnPrem')]
    procedure CheckPostedDocsInPostedBGPO(var GLEntry: Record "G/L Entry"): Boolean
    begin
        if GLEntry."Document Type" = GLEntry."Document Type"::Bill then begin
            PostedDoc.SetCurrentKey("Bill Gr./Pmt. Order No.", Status, "Category Code", Redrawn, "Due Date");
            PostedDoc.SetRange("Bill Gr./Pmt. Order No.", GLEntry."Document No.");
            if PostedDoc.FindFirst() then
                exit(true);

            ClosedDoc.SetCurrentKey(Type, "Bill Gr./Pmt. Order No.", "Global Dimension 1 Code", "Global Dimension 2 Code",
              "Currency Code", Status, Redrawn);
            ClosedDoc.SetRange("Bill Gr./Pmt. Order No.", GLEntry."Document No.");
            if ClosedDoc.FindFirst() then
                exit(true);
        end else begin
            PostedDoc.SetCurrentKey(Type, "Document No.");
            PostedDoc.SetRange("Document No.", GLEntry."Document No.");
            if PostedDoc.FindFirst() then
                exit(true);

            ClosedDoc.SetCurrentKey(Type, "Document No.");
            ClosedDoc.SetRange("Document No.", GLEntry."Document No.");
            if ClosedDoc.FindFirst() then
                exit(true);
        end;

        exit(false);
    end;
}

