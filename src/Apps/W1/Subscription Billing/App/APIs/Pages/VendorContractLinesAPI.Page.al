#pragma warning disable AA0247
page 8047 "Vendor Contract Lines API"
{
    APIGroup = 'subsBilling';
    APIPublisher = 'microsoft';
    APIVersion = 'v1.0';
    ApplicationArea = All;
    EntityName = 'vendorContractLines';
    EntitySetName = 'vendorContractLines';
    PageType = API;
    SourceTable = "Vend. Sub. Contract Line";
    Editable = false;
    DataAccessIntent = ReadOnly;
    AboutText = 'Exposes vendor subscription contract line records linking contracts to subscription headers and subscription line entries. Provides read-only access with nested vendor contract deferrals, enabling integration with external cost tracking and accounts payable reconciliation systems.';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(contractNo; Rec."Subscription Contract No.")
                {
                }
                field(contractLineNo; Rec."Line No.")
                {
                }
                field(serviceObjectNo; Rec."Subscription Header No.")
                {
                }
                field(serviceCommitmentLineNo; Rec."Subscription Line Entry No.")
                {
                }
                part(VendContractDeferralsAPI; "Vend. Contract Deferrals API")
                {
                    Caption = 'vendorContractDeferrals', Locked = true;
                    EntityName = 'vendorContractDeferrals';
                    EntitySetName = 'vendorContractDeferrals';
                    SubPageLink = "Subscription Contract No." = field("Subscription Contract No."), "Subscription Contract Line No." = field("Line No.");
                }
            }
        }
    }
}
