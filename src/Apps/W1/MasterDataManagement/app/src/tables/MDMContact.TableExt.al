namespace Microsoft.Integration.MDM;

using Microsoft.CRM.Contact;

tableextension 7246 "MDM Contact" extends Contact
{
    keys
    {
        // Change-feed order for cross-environment paging (SystemModifiedAt seek + SystemId tiebreak).
        key(MDMChangeFeed; SystemModifiedAt, SystemId)
        {
        }
    }
}
