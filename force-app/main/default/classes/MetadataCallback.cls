public class MetadataCallback implements Metadata.DeployCallback {
    public void handleResult(Metadata.DeployResult result,
                             Metadata.DeployCallbackContext context) {
        if (result.status == Metadata.DeployStatus.Succeeded) {
            // Deployment was successful
            System.debug('Metadata deployment successful.\nDeployed by: ' + result.createdByName + ' on ' + result.completedDate);
        } else {
            // Deployment was not successful
            System.debug('Metadata deployment encountered a problem:\n' + result.errorMessage);
        }
    }
}
