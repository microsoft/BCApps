codeunit 166500 "Create Post Dated ChecK"
{

    trigger OnRun()
    begin
        PostDatedCheck.DeleteAll();
        DemoDataSetup.Get();
        InsertLine('10000', PostDatedCheck."Account Type"::Customer, X1001, 20090107D, '00223212', -100135, 20090110D, '', '', '');
        InsertLine('30000', PostDatedCheck."Account Type"::Customer, X1002, 20090112D, '6001222', -230, 20090113D, '', '', '');
        InsertLine('10000', PostDatedCheck."Account Type"::Customer, X1003, 20090112D, '00223224',
                    -1104225, 20080113D, '', XCallcustomerbeforebanking, '');
        InsertLine('50000', PostDatedCheck."Account Type"::Customer, X1004, 20090106D, '82662232', -122, 20090109D, '', '', '');
        InsertLine('44171511', PostDatedCheck."Account Type"::Customer, X1005, 20090111D, '40002211', -7370, 20090115D, '', '', '');
        InsertLine('10000', PostDatedCheck."Account Type"::Customer, X1006, 20090104D, '00223301', -1290220, 20090105D, '', XReplacesCheck, '');

        InsertLine('10000', PostDatedCheck."Account Type"::Vendor, X2001, 20090105D, '22321112', 109133, 20090110D, '', '', XWWBOPERATING);
        InsertLine('01863656', PostDatedCheck."Account Type"::Vendor, X2002, 20090103D, '27343917',
                    2069132, 20080110D, '', XReplacesCheck, XWWBOPERATING);
        InsertLine('40000', PostDatedCheck."Account Type"::Vendor, X2003, 20090112D, '40326118', 107615, 20090115D, '', '', XWWBOPERATING);
        InsertLine('20000', PostDatedCheck."Account Type"::Vendor, X2004, 20090112D, '96331412', 30180, 20090118D, '', '', XWWBOPERATING);
        InsertLine('40000', PostDatedCheck."Account Type"::Vendor, X2005, 20090116D, '56741372', 164893, 20090116D, '', '', XWWBOPERATING);
    end;

    var
        XCallcustomerbeforebanking: Label 'Call customer before banking';
        XReplacesCheck: Label 'Replaces Check';
        XWWBOPERATING: Label 'WWB-OPERATING';
        X1001: Label '1001';
        X1002: Label '1002';
        X1003: Label '1003';
        X1004: Label '1004';
        X1005: Label '1005';
        X1006: Label '1006';
        X2001: Label '2001';
        X2002: Label '2002';
        X2003: Label '2003';
        X2004: Label '2004';
        X2005: Label '2005';
        PostDatedCheck: Record "Post Dated Check Line";
        DemoDataSetup: Record "Demo Data Setup";
        LineNumber: Integer;

    procedure InsertLine(No: Code[20]; "Account Type": Integer; "Document No": Text[30]; CheckDate: Date; CheckNo: Code[20]; Amount: Decimal; Received: Date; Currency: Code[20]; Comments: Text[90]; "Bank Account": Text[30])
    begin
        CheckDate := DMY2Date(Date2DMY(CheckDate, 1), Date2DMY(CheckDate, 2), Date2DMY(DemoDataSetup."Working Date", 3));
        Received := DMY2Date(Date2DMY(Received, 1), Date2DMY(Received, 2), Date2DMY(DemoDataSetup."Working Date", 3));
        PostDatedCheck.Init();
        PostDatedCheck."Line Number" := LineNumber;
        PostDatedCheck."Account Type" := "Account Type";
        PostDatedCheck.Validate("Account No.", No);
        PostDatedCheck."Document No." := "Document No";
        PostDatedCheck."Check Date" := CheckDate;
        PostDatedCheck."Check No." := CheckNo;
        PostDatedCheck.Validate("Currency Code", Currency);
        PostDatedCheck."Date Received" := Received;
        PostDatedCheck.Validate(Amount, Amount);
        PostDatedCheck.Comment := Comments;
        PostDatedCheck."Bank Account" := "Bank Account";
        PostDatedCheck.Insert();
        LineNumber := LineNumber + 10000;
    end;
}

