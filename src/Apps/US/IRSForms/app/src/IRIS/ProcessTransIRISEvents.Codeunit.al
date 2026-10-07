namespace Microsoft.Finance.VAT.Reporting;

codeunit 10061 "Process Trans. IRIS Events"
{
    /// <summary>
    /// Raises the OnAddReleasedFormDocsToTransmissionOnBeforeIRS1099FormDocHeaderFindSet integration event.
    /// </summary>
    /// <param name="IRS1099FormDocHeader">The IRS 1099 Form Doc. Header record to filter.</param>
    /// <param name="Transmission">The Transmission IRIS record.</param>
    procedure RunOnAddReleasedFormDocsToTransmissionOnBeforeIRS1099FormDocHeaderFindSet(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; var Transmission: Record "Transmission IRIS")
    begin
        OnAddReleasedFormDocsToTransmissionOnBeforeIRS1099FormDocHeaderFindSet(IRS1099FormDocHeader, Transmission);
    end;

    /// <summary>
    /// Raised before FindSet is called on IRS 1099 Form Doc. Header in AddReleasedFormDocsToTransmission, allowing subscribers to apply additional filters.
    /// </summary>
    /// <param name="IRS1099FormDocHeader">The IRS 1099 Form Doc. Header record being filtered.</param>
    /// <param name="Transmission">The Transmission IRIS record.</param>
    [IntegrationEvent(false, false)]
    procedure OnAddReleasedFormDocsToTransmissionOnBeforeIRS1099FormDocHeaderFindSet(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; var Transmission: Record "Transmission IRIS")
    begin
    end;
}
