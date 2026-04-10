#pragma warning disable AA0247
report 14972 "Suggest VAT Reinst. Lines"
{
    Caption = 'Suggest VAT Reinst. Lines';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DateFilter; DateFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Date Filter';
                        ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                        trigger OnValidate()
                        begin
                            VATDocumentEntryBuffer.SetFilter("Date Filter", DateFilter);
                            DateFilter := VATDocumentEntryBuffer.GetFilter("Date Filter");
                        end;
                    }
                    field(VATBusPostingGroupFilter; VATBusPostingGroupFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Bus. Posting Group Filter';
                        TableRelation = "VAT Business Posting Group";
                    }
                    field(VATProdPostingGroupFilter; VATProdPostingGroupFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Prod. Posting Group Filter';
                        TableRelation = "VAT Product Posting Group";
                        ToolTip = 'Specifies a filter for data to be included. VAT product posting groups define the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        VATDocumentEntryBuffer.SetFilter("Date Filter", DateFilter);
        VATReinstatementMgt.Generate(VATDocumentEntryBuffer, DateFilter, VATBusPostingGroupFilter, VATProdPostingGroupFilter);
    end;

    var
        VATDocumentEntryBuffer: Record "VAT Document Entry Buffer" temporary;
        VATReinstatementMgt: Codeunit "VAT Reinstatement Management";
        DateFilter: Text;
        VATBusPostingGroupFilter: Text;
        VATProdPostingGroupFilter: Text;

    [Scope('OnPrem')]
    procedure GetBuffer(var NewVATDocumentEntryBuffer: Record "VAT Document Entry Buffer")
    begin
        NewVATDocumentEntryBuffer.Reset();
        NewVATDocumentEntryBuffer.DeleteAll();
        if VATDocumentEntryBuffer.FindSet() then
            repeat
                NewVATDocumentEntryBuffer := VATDocumentEntryBuffer;
                NewVATDocumentEntryBuffer.Insert();
            until VATDocumentEntryBuffer.Next() = 0;
    end;
}

