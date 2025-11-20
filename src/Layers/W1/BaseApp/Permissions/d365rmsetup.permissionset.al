namespace System.Security.AccessControl;

using Microsoft.CRM.Task;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Profiling;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Team;

permissionset 8583 "D365 RM SETUP"
{
    Assignable = true;

    Caption = 'Dynamics 365 Rlshp. Mgt. Setup';
    Permissions = tabledata Activity = RIMD,
                  tabledata "Activity Step" = RIMD,
                  tabledata Attachment = RIMD,
                  tabledata "Business Relation" = RIMD,
                  tabledata "Close Opportunity Code" = RIMD,
                  tabledata "Duplicate Search String Setup" = RIMD,
                  tabledata "Industry Group" = RIMD,
                  tabledata "Interaction Group" = RIMD,
                  tabledata "Interaction Template" = RIMD,
                  tabledata "Interaction Tmpl. Language" = RIMD,
                  tabledata "Job Responsibility" = RIMD,
                  tabledata "Mailing Group" = RIMD,
                  tabledata "Marketing Setup" = IM,
                  tabledata "Organizational Level" = RIMD,
                  tabledata "Profile Questionnaire Header" = RIMD,
                  tabledata "Profile Questionnaire Line" = RIMD,
                  tabledata Rating = RIMD,
                  tabledata "Sales Cycle" = RIMD,
                  tabledata "Sales Cycle Stage" = RIMD,
                  tabledata Salutation = RIMD,
                  tabledata "Salutation Formula" = RIMD,
                  tabledata "Saved Segment Criteria" = RIMD,
                  tabledata "Saved Segment Criteria Line" = RIMD,
                  tabledata "Segment Criteria Line" = RIMD,
                  tabledata "Segment Header" = RIMD,
                  tabledata "Segment History" = RIMD,
                  tabledata "Segment Line" = RIMD,
                  tabledata "Segment Wizard Filter" = RIMD,
                  tabledata Team = RIMD,
                  tabledata "Team Salesperson" = RIMD,
                  tabledata "To-do Interaction Language" = RIMD,
                  tabledata "Web Source" = RIMD;
}
