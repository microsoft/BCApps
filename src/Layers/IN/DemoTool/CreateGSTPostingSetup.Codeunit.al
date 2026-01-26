codeunit 120548 "Create GST Posting Setup"
{
    trigger OnRun()

    begin
        DemoDataSetup.Get();
        InsertData(
            XNDStateCode, 2, '2703', '5983', '2706', '5986', '5987', '2707', '2710', '2712', '2717', '2500', '2501', '5989', '');
        InsertData(
            XNDStateCode, 3, '2701', '5981', '2704', '5984', '5987', '2707', '2711', '2714', '2715', '2500', '2501', '5989', '2720');
        InsertData(
            XNDStateCode, 6, '2702', '5982', '2705', '5985', '5987', '2707', '2709', '2713', '2716', '2500', '2501', '5989', '');
        InsertData(
            XHRStateCoe, 2, '2703', '5983', '2706', '5986', '5987', '2707', '2710', '2712', '2717', '2500', '2501', '5989', '');
        InsertData(
            XHRStateCoe, 3, '2701', '5981', '2704', '5984', '5987', '2707', '2711', '2714', '2715', '2500', '2501', '5989', '2720');
        InsertData(
            XHRStateCoe, 6, '2702', '5982', '2705', '5985', '5987', '2707', '2709', '2713', '2716', '2500', '2501', '5989', '');

        CreateGSTCompRecon('CGST', 17, 'Component 2 Amount', 9, 'Distributed as Component 2');
        CreateGSTCompRecon('IGST', 19, 'Component 3 Amount', 10, 'Distributed as Component 3');
        CreateGSTCompRecon('SGST', 15, 'Component 1 Amount', 8, 'Distributed as Component 1');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        GSTPostingSetup: Record "GST Posting Setup";
        XNDStateCode: Label 'DL';
        XHRStateCoe: Label 'HR';


    procedure InsertData(StateCode: Code[10]; CompId: Integer; ReceivableAcc: Code[20];
        PaybleAcc: Code[20]; ReceiveableAccInt: Code[20]; PaybleAccInt: Code[20]; ExpenseAcc: Code[20];
        RefundAcc: Code[20]; ReceivableAccIntDist: Code[20]; ReceivableAccDist: Code[20]; GSTCreditMismatch: Code[20]
        ; GSTTDSRecAcc: Code[20]; GSTTCSRecAcc: Code[20]; GSTTCSPaybleAcc: Code[20]; IGSTPayableAccImport: Code[20])
    begin
        DemoDataSetup.Get();
        GSTPostingSetup.Init();
        GSTPostingSetup."State Code" := StateCode;
        GSTPostingSetup."Component ID" := CompId;
        GSTPostingSetup."Receivable Account" := ReceivableAcc;
        GSTPostingSetup."Payable Account" := PaybleAcc;
        GSTPostingSetup."Receivable Account (Interim)" := ReceiveableAccInt;
        GSTPostingSetup."Payables Account (Interim)" := PaybleAccInt;
        GSTPostingSetup."Expense Account" := ExpenseAcc;
        GSTPostingSetup."Refund Account" := RefundAcc;
        GSTPostingSetup."Receivable Acc. Interim (Dist)" := ReceivableAccIntDist;
        GSTPostingSetup."Receivable Acc. (Dist)" := ReceivableAccDist;
        GSTPostingSetup."GST Credit Mismatch Account" := GSTCreditMismatch;
        GSTPostingSetup."GST TDS Receivable Account" := GSTTDSRecAcc;
        GSTPostingSetup."GST TCS Receivable Account" := GSTTCSRecAcc;
        GSTPostingSetup."GST TCS Payable Account" := GSTTCSPaybleAcc;
        GSTPostingSetup."IGST Payable A/c (Import)" := IGSTPayableAccImport;
        GSTPostingSetup.Insert();
    end;

    local procedure CreateGSTCompRecon(Comp: Code[10]; FieldNo: Integer; FieldName: Text[30]; ISDFieldNo: Integer; ISDFieldName: Text[30])
    var
        GSTReconMapping: Record "GST Recon. Mapping";
    begin
        GSTReconMapping.Init();
        GSTReconMapping."GST Component Code" := Comp;
        GSTReconMapping."GST Reconciliation Field No." := FieldNo;
        GSTReconMapping."GST Reconciliation Field Name" := FieldName;
        GSTReconMapping."ISD Ledger Field No." := ISDFieldNo;
        GSTReconMapping."ISD Ledger Field Name" := ISDFieldName;
        GSTReconMapping.Insert();

    end;
}