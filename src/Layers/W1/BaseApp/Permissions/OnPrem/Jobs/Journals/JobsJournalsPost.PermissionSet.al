namespace System.Security.AccessControl;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Period;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.WIP;
using Microsoft.Projects.TimeSheet;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Setup;

permissionset 3414 "Jobs Journals - Post"
{
    Access = Public;
    Assignable = false;
    Caption = 'Post project journals';

    Permissions = tabledata "Accounting Period" = R,
                  tabledata "Dimension Combination" = R,
                  tabledata "Dimension Value Combination" = R,
                  tabledata "General Ledger Setup" = R,
                  tabledata "General Posting Setup" = R,
                  tabledata Job = R,
                  tabledata "Job Journal Batch" = RID,
                  tabledata "Job Journal Line" = RIMD,
                  tabledata "Job Journal Template" = RI,
                  tabledata "Job Ledger Entry" = Rim,
                  tabledata "Job Planning Line - Calendar" = Rimd,
                  tabledata "Job Planning Line" = Rimd,
                  tabledata "Job Register" = Rim,
                  tabledata "Job Task" = R,
                  tabledata "Job WIP Entry" = R,
                  tabledata "Job WIP G/L Entry" = R,
                  tabledata "Time Sheet Chart Setup" = R,
                  tabledata "Time Sheet Detail" = Rm,
                  tabledata "Time Sheet Header" = R,
                  tabledata "Time Sheet Line" = Rm,
                  tabledata "Time Sheet Posting Entry" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Setup" = R;
}
