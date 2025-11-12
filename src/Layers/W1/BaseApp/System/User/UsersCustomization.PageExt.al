namespace System.Security.User;

using Microsoft.AccountantPortal;
using Microsoft.CRM.Team;
using Microsoft.FixedAssets.Journal;
using Microsoft.Foundation.Task;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Vendor;
using System.EMail;
using System.Azure.Identity;
using System.Security.AccessControl;
using System.Device;
using Microsoft.Sales.Customer;
using Microsoft.Warehouse.Setup;

pageextension 9801 "Users Customization" extends Users
{
    layout
    {
        addfirst(factboxes)
        {
            part(Control18; "Permission Sets FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "User Security ID" = field("User Security ID");
                Visible = CanManageUsersOnTenant or IsOwnUser;
            }
        }

        addafter(Plans)
        {
            part(Control20; "User Setup FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "User ID" = field("User Name");
            }
        }

        addlast(factboxes)
        {
            part(Control32; "Printer Selections FactBox")
            {
                ApplicationArea = Basic, Suite;
                ShowFilter = false;
                SubPageLink = "User ID" = field("User Name");
            }
            part(Control28; "My Customers")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ShowFilter = false;
                SubPageLink = "User ID" = field("User Name");
                Visible = false;
            }
            part(Control29; "My Vendors")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ShowFilter = false;
                SubPageLink = "User ID" = field("User Name");
                Visible = false;
            }
            part(Control30; "My Items")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ShowFilter = false;
                SubPageLink = "User ID" = field("User Name");
                Visible = false;
            }
        }
    }

    actions
    {
        addlast("User Groups")
        {
            action("User Task Groups")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Task Groups';
                Image = Users;
                RunObject = Page "User Task Groups";
                ToolTip = 'Add or modify groups of users that you can assign user tasks to in this company.';
            }
        }

        addafter("User Groups")
        {
            group(Permissions)
            {
                Caption = 'Permissions';
                action("Effective Permissions")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Effective Permissions';
                    Image = Permission;
                    Scope = Repeater;
                    ToolTip = 'View this user''s actual permissions for all objects per assigned permission set, and edit the user''s permissions in permission sets of type User-Defined.';

                    trigger OnAction()
                    var
                        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
                    begin
                        EffectivePermissionsMgt.OpenPageForUser(Rec."User Security ID");
                    end;
                }
                action("Permission Sets")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Sets';
                    Image = Permission;
                    RunObject = Page "Permission Sets";
                    ToolTip = 'View or edit which feature objects that users need to access and set up the related permissions in permission sets that you can assign to the users of the database.';
                }
                action("Permission Set by User")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set by User';
                    Image = Permission;
                    RunObject = Page "Permission Set by User";
                    ToolTip = 'View or edit the available permission sets and apply permission sets to existing users.';
                }
                action("Permission Set By Security Group")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set by Security Group';
                    Image = Permission;
                    RunObject = Page "Permission Set By Sec. Group";
                    ToolTip = 'View or edit the available permission sets and apply permission sets to existing security groups.';
                }
            }
        }

        addlast(navigation)
        {
            action("User Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Setup';
                Image = UserSetup;
                RunObject = Page "User Setup";
                ToolTip = 'Make additional choices for certain users.';

                AboutTitle = 'Additional setup for users';
                AboutText = 'Here, you can define when certain users can post transactions. You can also designate time sheet roles or associate users with sales/purchaser codes.';
            }
            action("Printer Selections")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Printer Selections';
                Image = Print;
                RunObject = Page "Printer Selections";
                ToolTip = 'Assign printers to users and/or reports so that a user always uses a specific printer, or a specific report only prints on a specific printer.';
            }
            action("Warehouse Employees")
            {
                ApplicationArea = Warehouse;
                Caption = 'Warehouse Employees';
                Image = WarehouseSetup;
                RunObject = Page "Warehouse Employees";
                ToolTip = 'View the warehouse employees that exist in the system.';
            }

            action("Employees")
            {
                ApplicationArea = BasicHR;
                Caption = 'Employees';
                Image = Employee;
                RunObject = Page "Employee List";
                ToolTip = 'View the employees that exist in the system.';
            }
            action("Resources")
            {
                ApplicationArea = Jobs;
                Caption = 'Resources';
                Image = Resource;
                RunObject = Page "Resource List";
                ToolTip = 'View the resources that exist in the system.';
            }
            action("Salespersons/Purchasers")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Salespeople/Purchasers';
                Image = Users;
                RunObject = Page "Salespersons/Purchasers";
                ToolTip = 'View the salespeople/purchasers that exist in the system.';
            }
            action("FA Journal Setup")
            {
                ApplicationArea = FixedAssets;
                Caption = 'FA Journal Setup';
                Image = FixedAssets;
                RunObject = Page "FA Journal Setup";
                ToolTip = 'Set up journals, journal templates, and journal batches for fixed assets.';
            }
        }

        addafter(AddMeAsSuper)
        {
            action("Invite External Accountant")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Invite external accountant';
                Image = SalesPerson;
                ToolTip = 'Set up an external accountant with access to your Dynamics 365.';
                Visible = IsSaaS;

                trigger OnAction()
                begin
                    Page.Run(Page::"Invite External Accountant");
                    CurrPage.Update(false);
                end;
            }
            action("Restore User Default Permissions")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Restore User''s Default Permissions';
                Enabled = not NoUserExists;
                Image = UserInterface;
                ToolTip = 'Restore the default permissions based on changes to the related plan.';
                Visible = IsSaaS and CanManageUsersOnTenant;

                trigger OnAction()
                var
                    PermissionManager: Codeunit "Permission Manager";
                    AzureADPlan: Codeunit "Azure AD Plan";
                begin
                    if Confirm(RestoreUserGroupsToDefaultQst, false, Rec."User Name") then begin
                        AzureADPlan.RefreshUserPlanAssignments(Rec."User Security ID");
                        PermissionManager.ResetUserToDefaultPermissions(Rec."User Security ID");
                    end;
                end;
            }
        }
        addlast(processing)
        {
            action(Email)
            {
                ApplicationArea = All;
                Caption = 'Send Email';
                Image = Email;
                ToolTip = 'Send an email to this user.';
                Enabled = CanSendEmail;

                trigger OnAction()
                var
                    TempEmailItem: Record "Email Item" temporary;
                    EmailScenario: Enum "Email Scenario";
                begin
                    TempEmailItem.AddSourceDocument(Database::User, Rec.SystemId);
                    TempEmailItem."Send to" := Rec."Contact Email";
                    TempEmailItem.Send(false, EmailScenario::Default);
                end;
            }
        }

        addfirst(Category_Process)
        {
            actionref("Effective Permissions_Promoted"; "Effective Permissions")
            {
            }
            actionref("Invite External Accountant_Promoted"; "Invite External Accountant")
            {
            }
            actionref(Email_Promoted; Email)
            {
            }
        }
        addafter("Security Groups_Promoted")
        {
            actionref("User Task Groups_Promoted"; "User Task Groups")
            {
            }
            actionref("Permission Sets_Promoted"; "Permission Sets")
            {
            }
        }
        addlast(Category_Category4)
        {
            actionref("User Setup_Promoted"; "User Setup")
            {
            }
            actionref("Printer Selections_Promoted"; "Printer Selections")
            {
            }
            actionref("Warehouse Employees_Promoted"; "Warehouse Employees")
            {
            }
            actionref("FA Journal Setup_Promoted"; "FA Journal Setup")
            {
            }
        }
    }

    var
#pragma warning disable AA0470
        RestoreUserGroupsToDefaultQst: Label 'Do you want to restore the default permissions for user %1?', Comment = 'Do you want to restore the default permissions for user Annie?';
#pragma warning restore AA0470
        CanSendEmail: Boolean;

    trigger OnAfterGetCurrRecord()
    var
        User: Record User;
    begin
        CurrPage.SetSelectionFilter(User);
        CanSendEmail := User.Count() = 1;
    end;
}
