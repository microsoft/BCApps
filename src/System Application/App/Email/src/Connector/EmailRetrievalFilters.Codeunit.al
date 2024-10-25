namespace System.Email;

/// <summary>
/// This codeunit is used to store the filters for email connectors to use when retrieving emails.
/// </summary>
/// <remarks>
/// Not all email connectors may use all the filters.
/// </remarks>
codeunit 4534 "Email Retrieval Filters"
{
    var
        Initialized: Boolean;
        LoadAttachments: Boolean;
        Unread: Boolean;
        Draft: Boolean;
        MaxNoOfEmails: Integer;
        BodyasHtml: Boolean;
        EarliestEmails: DateTime;

    #region Getters
    procedure GetLoadAttachments(): Boolean
    begin
        Initialize();
        exit(LoadAttachments);
    end;

    procedure GetUnread(): Boolean
    begin
        Initialize();
        exit(Unread);
    end;

    procedure GetDraft(): Boolean
    begin
        Initialize();
        exit(Draft);
    end;

    procedure GetMaxNoOfEmails(): Integer
    begin
        Initialize();
        exit(MaxNoOfEmails);
    end;

    procedure GetBodyAsHtml(): Boolean
    begin
        Initialize();
        exit(BodyasHtml);
    end;

    procedure GetEarliestEmails(): DateTime
    begin
        Initialize();
        exit(EarliestEmails);
    end;
    #endregion

    #region Setters
    procedure SetLoadAttachments(Value: Boolean)
    begin
        Initialize();
        LoadAttachments := Value;
    end;

    procedure SetUnread(Value: Boolean)
    begin
        Initialize();
        Unread := Value;
    end;

    procedure SetDraft(Value: Boolean)
    begin
        Initialize();
        Draft := Value;
    end;

    procedure SetMaxNoOfEmails(Value: Integer)
    begin
        Initialize();
        MaxNoOfEmails := Value;
    end;

    procedure SetBodyAsHtml(Value: Boolean)
    begin
        Initialize();
        BodyasHtml := Value;
    end;

    procedure SetEarliestEmails(Value: DateTime)
    begin
        Initialize();
        EarliestEmails := Value;
    end;
    #endregion

    local procedure Initialize()
    begin
        if Initialized then
            exit;

        LoadAttachments := false;
        Unread := false;
        Draft := false;
        MaxNoOfEmails := 20;
        BodyasHtml := false;
        Initialized := true;
        EarliestEmails := 0DT; // All emails
    end;
}