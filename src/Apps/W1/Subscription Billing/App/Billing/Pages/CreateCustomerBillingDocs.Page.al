namespace Microsoft.SubscriptionBilling;

page 8072 "Create Customer Billing Docs"
{
    Caption = 'Create Billing Documents';
    PageType = StandardDialog;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            group(DateFields)
            {
                Caption = 'Dates';
                field(DocumentDate; DocumentDate)
                {
                    Caption = 'Document Date';
                    ToolTip = 'Specifies the date which is taken over as the document date in the sales documents.';
                }
                field(PostingDate; PostingDate)
                {
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies the date which is used as the posting date in the sales documents.';
                }
                field(PostDocuments; PostDocuments)
                {
                    Caption = 'Post Document(s)';
                    ToolTip = 'Specifies whether the created documents will be posted automatically.';
                }
            }
            group(OptionFields)
            {
                Caption = 'Options';
                field(GroupingType; Grouping)
                {
                    Caption = 'Document per';
                    ToolTip = 'Specifies how the billing lines are grouped in the sales documents.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if DocumentDate = 0D then
            DocumentDate := WorkDate();
        if PostingDate = 0D then
            PostingDate := WorkDate();
    end;

    var
        DocumentDate: Date;
        PostingDate: Date;
        PostDocuments: Boolean;
        Grouping: Enum "Customer Rec. Billing Grouping";

    internal procedure GetData(var NewDocumentDate: Date; var NewPostingDate: Date; var NewGroupingType: Enum "Customer Rec. Billing Grouping"; var NewPostDocuments: Boolean)
    begin
        NewDocumentDate := DocumentDate;
        NewPostingDate := PostingDate;
        NewGroupingType := Grouping;
        NewPostDocuments := PostDocuments;
    end;

    internal procedure SetData(var NewDocumentDate: Date; var NewPostingDate: Date; var NewGroupingType: Enum "Customer Rec. Billing Grouping"; var NewPostDocuments: Boolean)
    begin
        DocumentDate := NewDocumentDate;
        PostingDate := NewPostingDate;
        Grouping := NewGroupingType;
        PostDocuments := NewPostDocuments;
    end;

}