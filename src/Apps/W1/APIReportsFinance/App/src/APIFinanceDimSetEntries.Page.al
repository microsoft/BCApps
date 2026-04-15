namespace Microsoft.API.FinancialManagement;

using Microsoft.Finance.Dimension;

page 30303 "API Finance - Dim Set Entries"
{
    PageType = API;
    EntityCaption = 'Dimension Set Entries';
    EntityName = 'dimensionSetEntry';
    EntitySetName = 'dimensionSetEntries';
    APIGroup = 'reportsFinance';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DataAccessIntent = ReadOnly;
    ODataKeyFields = SystemId;
    SourceTable = "Dimension Set Entry";
    AboutText = 'Provides access to dimension set entry data from the Dimension Set Entry table, including dimension set IDs, dimension codes and names, and dimension value codes and names. Supports read-only GET operations for retrieving dimension combinations assigned to transactions to enable integration with external financial reporting and analytics platforms.';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                }
                field(setId; Rec."Dimension Set ID")
                {
                    Caption = 'Dimension Set ID';
                }
                field(dimensionCode; Rec."Dimension Code")
                {
                    Caption = 'Dimension Code';
                }
                field(dimensionDisplayName; Rec."Dimension Name")
                {
                    Caption = 'Dimension Name';
                }
                field(dimensionValueCode; Rec."Dimension Value Code")
                {
                    Caption = 'Dimension Value Code';
                }
                field(dimensionValueDisplayName; Rec."Dimension Value Name")
                {
                    Caption = 'Dimension Value Name';
                }
                field(dimensionValueId; Rec."Dimension Value ID")
                {
                    Caption = 'Dimension Value ID';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last  Modified Date Time';
                }
            }
        }
    }
}
