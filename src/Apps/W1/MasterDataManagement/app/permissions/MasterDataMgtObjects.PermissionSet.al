namespace Microsoft.Integration.MDM;

/// <summary>
/// this permission set is used to easily add all the extension objects into the apps license
/// do not include this permission set in any other permission set
/// and do not change the Access and Assignable properties
/// </summary>
permissionset 7230 "Master Data Mgt. - Objects"
{
    Assignable = false;
    Access = Public;

    Permissions = codeunit "Master Data Mgt. Setup Default" = X,
                  codeunit "Integration Master Data Synch." = X,
                  codeunit "Master Data Management" = X,
                  codeunit "Master Data Mgt. Table Couple" = X,
                  codeunit "Master Data Mgt. Tbl. Uncouple" = X,
                  codeunit "Master Data Mgt. Subscribers" = X,
                  codeunit "Master Data Mgt. Upgrade" = X,
                  codeunit "Master Data Mgt. Install" = X,
                  codeunit "MDM Local Data Source" = X,
                  codeunit "MDM Source Response" = X,
                  codeunit "MDM Http Source Transport" = X,
                  codeunit "MDM Cross-Env Data Source" = X,
                  codeunit "MDM Source Connection" = X,
                  codeunit "MDM Cross-Env Change Detector" = X,
                  codeunit "MDM Source Capabilities" = X,
                  codeunit "MDM Inline Media" = X,
                  codeunit "MDM Source Watermark" = X,
                  codeunit "MDM Privacy Notice" = X,
                  page * = X,
                  table * = X,
                  xmlport * = X;
}