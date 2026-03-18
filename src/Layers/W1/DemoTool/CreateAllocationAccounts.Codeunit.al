codeunit 101346 "Create Allocation Accounts"
{
    trigger OnRun()
    begin
        CreateFixedAccounts();
    end;

    local procedure CreateFixedAccounts()
    var
        AllocationAccount: Record "Allocation Account";
        MakeAdjustments: Codeunit "Make Adjustments";
        CreateDimension: Codeunit "Create Dimension";
        CurrentLineNo: Integer;
    begin
        CreateFixedAllocationAccount(AdvertisingExpenseAccountNoLbl, AdvertisingExpenseAccountNameLbl, AllocationAccount);
        CurrentLineNo := 10000;
        CreateDistributionLines(CurrentLineNo, AllocationAccount, MakeAdjustments.Convert('998410'), CreateDimension.GetDepartmentCode(), CreateDimension.GetDepartmentAMDCode(), 20);
        CurrentLineNo += 10000;
        CreateDistributionLines(CurrentLineNo, AllocationAccount, MakeAdjustments.Convert('998410'), CreateDimension.GetDepartmentCode(), CreateDimension.GetDepartmentPRODCode(), 30);
        CurrentLineNo += 10000;
        CreateDistributionLines(CurrentLineNo, AllocationAccount, MakeAdjustments.Convert('998410'), CreateDimension.GetDepartmentCode(), CreateDimension.GetDepartmentSALESCode(), 50);
    end;

    local procedure CreateFixedAllocationAccount(AllocationAccountNo: Code[20]; AllocationAccountName: Text[100]; var AllocationAccount: Record "Allocation Account")
    begin
        AllocationAccount."No." := AllocationAccountNo;
        AllocationAccount.Name := AllocationAccountName;
        AllocationAccount."Account Type" := AllocationAccount."Account Type"::Fixed;
        AllocationAccount.Insert();
    end;

    local procedure CreateDistributionLines(CurrentLineNo: Integer; var AllocationAccount: Record "Allocation Account"; DestinationAccountNumber: Code[20]; DimensionCode: Code[20]; DimensionValueCode: Code[20]; DistributionShare: Integer)
    var
        AllocAccountDistribution: Record "Alloc. Account Distribution";
        DimensionValue: Record "Dimension Value";
    begin
        Clear(AllocAccountDistribution);
        AllocAccountDistribution."Allocation Account No." := AllocationAccount."No.";
        AllocAccountDistribution."Line No." := CurrentLineNo;
        AllocAccountDistribution."Account Type" := AllocAccountDistribution."Account Type"::Fixed;
        AllocAccountDistribution."Destination Account Type" := AllocAccountDistribution."Destination Account Type"::"G/L Account";
        AllocAccountDistribution."Destination Account Number" := DestinationAccountNumber;
        DimensionValue.Get(DimensionCode, DimensionValueCode);
        AllocAccountDistribution."Dimension Set ID" := GetDimensionSetID(DimensionValue);
        AllocAccountDistribution.Insert();
        AllocAccountDistribution.Validate(Share, DistributionShare);
        AllocAccountDistribution.Modify(true);
    end;

    local procedure GetDimensionSetID(DimensionValue: Record "Dimension Value"): Integer
    var
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        DimensionManagement: Codeunit DimensionManagement;
    begin
        TempDimensionSetEntry."Dimension Code" := DimensionValue."Dimension Code";
        TempDimensionSetEntry."Dimension Value Code" := DimensionValue.Code;
        TempDimensionSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
        TempDimensionSetEntry.Insert();
        exit(DimensionManagement.GetDimensionSetID(TempDimensionSetEntry));
    end;

    var
        AdvertisingExpenseAccountNameLbl: Label 'Advertising expense, alloc. per dept fixed';
        AdvertisingExpenseAccountNoLbl: Label 'ADVERT ALLOC', MaxLength = 20, Comment = 'Short for Advertising Allocation, maximum length 20 characters.';
}

