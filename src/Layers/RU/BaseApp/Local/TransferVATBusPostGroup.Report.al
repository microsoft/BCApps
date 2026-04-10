#pragma warning disable AA0247
report 14971 "Transfer VAT Bus. Post. Group"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Transfer VAT Business Posting Group';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(VATBusPostingGroup; "VAT Business Posting Group")
        {
            MaxIteration = 1;
            RequestFilterFields = "Code";

            trigger OnAfterGetRecord()
            begin
                NewVATBusPostGroup.Code := NewCode;
                NewVATBusPostGroup.Description :=
                  CopyStr(Description, 1, MaxStrLen(Description) - StrLen(StrSubstNo(Text001, BlockingDate))) + StrSubstNo(Text001, BlockingDate);
                NewVATBusPostGroup.Insert();

                Vendor.SetRange("VAT Bus. Posting Group", Code);
                Vendor.ModifyAll("VAT Bus. Posting Group", NewCode);

                Customer.SetRange("VAT Bus. Posting Group", Code);
                Customer.ModifyAll("VAT Bus. Posting Group", NewCode);

                GLAccount.SetRange("VAT Bus. Posting Group", Code);
                GLAccount.ModifyAll("VAT Bus. Posting Group", NewCode);

                VendorAgreement.SetRange("VAT Bus. Posting Group", Code);
                VendorAgreement.ModifyAll("VAT Bus. Posting Group", NewCode);

                CustomerAgreement.SetRange("VAT Bus. Posting Group", Code);
                CustomerAgreement.ModifyAll("VAT Bus. Posting Group", NewCode);

                VATPostingSetup.SetRange("VAT Bus. Posting Group", Code);
                if VATPostingSetup.Find('-') then
                    repeat
                        NewVATPostingSetup := VATPostingSetup;
                        NewVATPostingSetup."VAT Bus. Posting Group" := NewCode;
                        NewVATPostingSetup."Unrealized VAT Type" := 0;
                        NewVATPostingSetup."Manual VAT Settlement" := false;
                        NewVATPostingSetup.Insert();
                    until VATPostingSetup.Next() = 0;
            end;

            trigger OnPreDataItem()
            begin
                if BlockingDate = 0D then
                    BlockingDate := 20060101D;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NewCode; NewCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Code';
                        ToolTip = 'Specifies a new business posting group code that that will be used.';
                    }
                    field(BlockingDate; BlockingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Blocking Date';
                        Editable = false;
                        ToolTip = 'Specifies the date when certain transactions are blocked.';
                    }
                    field(ManualVATSettlement; ManualVATSettlement)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Manual VAT Settlement';
                        ToolTip = 'Specifies that you want to manually calculate and post the VAT settlement.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            BlockingDate := 20060101D;
        end;
    }

    labels
    {
    }

    var
        NewVATBusPostGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label ' (From %1)';
#pragma warning restore AA0470
#pragma warning restore AA0074
        NewVATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        Customer: Record Customer;
        VendorAgreement: Record "Vendor Agreement";
        CustomerAgreement: Record "Customer Agreement";
        GLAccount: Record "G/L Account";
        ManualVATSettlement: Boolean;
        NewCode: Code[10];
        BlockingDate: Date;
}

