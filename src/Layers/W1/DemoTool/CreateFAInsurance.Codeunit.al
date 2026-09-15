codeunit 101817 "Create FA Insurance"
{

    trigger OnRun()
    begin
        "Fixed Asset".Get(XFA000010);
        InsertData(
          XINS000010, "Fixed Asset".Description, 19030101D, XQW27425A, 4000, 35000, XCAR, '',
          "Fixed Asset"."FA Class Code", "Fixed Asset"."FA Subclass Code", "Fixed Asset"."Global Dimension 1 Code",
          "Fixed Asset"."Global Dimension 2 Code");
        "Fixed Asset".Get(XFA000020);
        InsertData(
          XINS000020, "Fixed Asset".Description, 19030101D, XQW37425A, 3000, 45000, XCAR, '',
          "Fixed Asset"."FA Class Code", "Fixed Asset"."FA Subclass Code", "Fixed Asset"."Global Dimension 1 Code",
          "Fixed Asset"."Global Dimension 2 Code");
        "Fixed Asset".Get(XFA000030);
        InsertData(
          XINS000030, "Fixed Asset".Description, 19030101D, 'QW 38425 A', 2000, 20000, XCAR, '',
          "Fixed Asset"."FA Class Code", "Fixed Asset"."FA Subclass Code", "Fixed Asset"."Global Dimension 1 Code",
          "Fixed Asset"."Global Dimension 2 Code");
        "Fixed Asset".Get(XFA000040);
        InsertData(
          XINS000040, XMachineryInsurance, 19030101D, XMA18425A, 10000, 30000, XMACHINERY, '',
          "Fixed Asset"."FA Class Code", "Fixed Asset"."FA Subclass Code", '', '');
    end;

    var
        "Fixed Asset": Record "Fixed Asset";
        Insurance: Record Insurance;
        CA: Codeunit "Make Adjustments";
        XFA000010: Label 'FA000010';
        XINS000010: Label 'INS000010';
        XQW27425A: Label 'QW 27425 A';
        XCAR: Label 'CAR';
        XFA000020: Label 'FA000020';
        XINS000020: Label 'INS000020';
        XQW37425A: Label 'QW 37425 A';
        XFA000040: Label 'FA000040';
        XINS000040: Label 'INS000040';
        XMachineryInsurance: Label 'Machinery Insurance';
        XMA18425A: Label 'MA 18425 A';
        XMACHINERY: Label 'MACHINERY';
        XINS000030: Label 'INS000030';
        XFA000030: Label 'FA000030';

    procedure InsertData("No.": Code[20]; Description: Text[100]; "Effective Date": Date; "Policy No.": Text[30]; "Annual Premium": Decimal; "Policy Coverage": Decimal; "Insurance Type": Code[10]; "Insurance Vendor No.": Code[20]; "FA Class Code": Code[10]; "FA Subclass Code": Code[10]; "Global Dimension 1 Code": Code[20]; "Global Dimension 2 Code": Code[20])
    begin
        Insurance.Init();
        Insurance.Validate("No.", "No.");
        Insurance.Validate(Description, Description);
        Insurance.Validate("Effective Date", CA.AdjustDate("Effective Date"));
        Insurance.Validate("Policy No.", "Policy No.");
        Insurance.Validate("Annual Premium", "Annual Premium");
        Insurance.Validate("Policy Coverage", "Policy Coverage");
        Insurance.Validate("Insurance Type", "Insurance Type");
        Insurance.Validate("Insurance Vendor No.", "Insurance Vendor No.");
        Insurance.Validate("FA Class Code", "FA Class Code");
        Insurance.Validate("FA Subclass Code", "FA Subclass Code");
        Insurance.Insert(true);
        Insurance.Validate("Global Dimension 1 Code", "Global Dimension 1 Code");
        Insurance.Validate("Global Dimension 2 Code", "Global Dimension 2 Code");
        Insurance.Modify();
    end;
}

