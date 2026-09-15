codeunit 131016 "Library - Power BI Service Mgt"
{
    // // Mock for Power BI Service Mgt (codeunit 6301) that unit tests can use to test Power BI pages without live PBI connections.

    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        MockExceptionMessage: Text;
        MockExceptionDetails: Text;
        MockDeploymentUploadSuccessful: Boolean;
        MockDeploymentRefreshSuccessful: Boolean;
        MockDeploymentServiceAvailable: Boolean;
        MockDeploymentShouldRetry: Boolean;
        MockDeploymentRetryAfter: DateTime;
        MockDeploymentUploadCount: Integer;
        MockDeploymentRetryCount: Integer;
        ContextTxt: Label 'Context1';

    [Scope('OnPrem')]
    procedure GetContext(): Text[30]
    begin
        exit(ContextTxt);
    end;

    procedure AddException(ExceptionMessage: Text; ExceptionDetails: Text)
    begin
        // Sets the values of the exception that gets returned when calling GetReports.
        MockExceptionMessage := ExceptionMessage;
        MockExceptionDetails := ExceptionDetails;
    end;

    procedure ClearException()
    begin
        // Clears the stored exception values that get returned when calling GetReports.
        MockExceptionMessage := '';
        MockExceptionDetails := '';
    end;

    procedure SetMockDeploymentResults(ServiceAvailable: Boolean; UploadSuccessful: Boolean; RefreshSuccessful: Boolean; ShouldRetry: Boolean; RetryAfter: DateTime)
    begin
        // Sets the intended output of any following calls to the mock deployment service (OnUploadReports/OnRetryUploads)
        // to simulate various success/failure states of the mock service.
        MockDeploymentServiceAvailable := ServiceAvailable;
        MockDeploymentUploadSuccessful := UploadSuccessful;
        MockDeploymentRefreshSuccessful := RefreshSuccessful;
        MockDeploymentShouldRetry := ShouldRetry;
        MockDeploymentRetryAfter := RetryAfter;
    end;

    procedure GetMockDeploymentUploadCount(): Integer
    begin
        // Gets cumulative number of reports that have been attempted to upload (regardless of success/failure).
        exit(MockDeploymentUploadCount);
    end;

    procedure GetMockDeploymentRetryCount(): Integer
    begin
        // Gets cumulative number of reports that have been attempted to retry (regardless of success/failure).
        exit(MockDeploymentRetryCount);
    end;

    procedure ResetMockDeploymentCounts()
    begin
        // Sets the counts of uploaded/retried reports back to 0 for starting a new unit test.
        MockDeploymentUploadCount := 0;
        MockDeploymentRetryCount := 0;
    end;
}
