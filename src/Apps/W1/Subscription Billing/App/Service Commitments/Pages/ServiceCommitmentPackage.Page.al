namespace Microsoft.SubscriptionBilling;

page 8056 "Service Commitment Package"
{
    Caption = 'Subscription Package';
    PageType = Card;
    SourceTable = "Subscription Package";
    UsageCategory = None;
    ApplicationArea = All;
    AdditionalSearchTerms = 'Subscription Package, Package Details, Package Lines, Subscription Template, Commitment Package, Package Setup';
    AboutTitle = 'About Subscription Package details';
    AboutText = 'Subscription elements are grouped together in the form of package lines so that they can be used.';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ShowMandatory = true;
                    ToolTip = 'Specifies a code to identify this Subscription Package.';
                    trigger OnValidate()
                    begin
                        PackageLinesEnabled := Rec.Code <> '';
                    end;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a description of the Subscription Package.';
                }
                field("Price Group"; Rec."Price Group")
                {
                    ToolTip = 'Specifies the customer price group that will be used for the invoicing of Subscription Lines.';
                }
            }
            part(PackageLines; "Service Comm. Package Lines")
            {
                Editable = DynamicEditable;
                Enabled = PackageLinesEnabled;
                SubPageLink = "Subscription Package Code" = field(Code);
                UpdatePropagation = Both;
                AboutTitle = 'Set up subscription lines';
                AboutText = 'The lines represent the elements made available by the package. Create new lines manually or by selecting a template.';
            }

        }
    }
    actions
    {
        area(Navigation)
        {
            action(AssignedItems)
            {
                Caption = 'Assigned Items';
                Image = ItemLedger;
                RunObject = page "Assigned Items";
                RunPageLink = Code = field(Code);
                ToolTip = 'Shows items related to a package.';
                AboutTitle = 'Subscription packages and items';
                AboutText = 'Display the items to which the subscription package is already assigned or assign it to other items if required.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(AssignedItems_Promoted; AssignedItems)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        PackageLinesEnabled := Rec.Code <> '';
    end;

    trigger OnAfterGetCurrRecord()
    begin
        DynamicEditable := CurrPage.Editable;
    end;

    var
        DynamicEditable: Boolean;
        PackageLinesEnabled: Boolean;
}
