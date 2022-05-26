/**
 * Copyright (c) 2012, FinancialForce.com, inc
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, 
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice, 
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice, 
 *      this list of conditions and the following disclaimer in the documentation 
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors 
 *      may be used to endorse or promote products derived from this software without 
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

/**
 * This is a dummy test class to obtain 100% coverage for the generated WSDL2Apex code, it is not a funcitonal test class
 *   You should follow the usual practices to cover your other code, as shown in the MetadataCreateJobTest.cls
 **/ 
@isTest  
private class Wrike_MetadataServiceTest
{    
    /**
     * Dummy Metadata API web service mock class (see MetadataCreateJobTest.cls for a better example)
     **/
    private class WebServiceMockImpl implements WebServiceMock 
    {
        public void doInvoke(
            Object stub, Object request, Map<String, Object> response,
            String endpoint, String soapAction, String requestName,
            String responseNS, String responseName, String responseType) 
        {
            if(request instanceof Wrike_MetadataService.retrieve_element)
                response.put('response_x', new Wrike_MetadataService.retrieveResponse_element());
            else if(request instanceof Wrike_MetadataService.checkDeployStatus_element)
                response.put('response_x', new Wrike_MetadataService.checkDeployStatusResponse_element());
            else if(request instanceof Wrike_MetadataService.listMetadata_element)
                response.put('response_x', new Wrike_MetadataService.listMetadataResponse_element());
            else if(request instanceof Wrike_MetadataService.checkRetrieveStatus_element)
                response.put('response_x', new Wrike_MetadataService.checkRetrieveStatusResponse_element());
            else if(request instanceof Wrike_MetadataService.describeMetadata_element)
                response.put('response_x', new Wrike_MetadataService.describeMetadataResponse_element());
            else if(request instanceof Wrike_MetadataService.deploy_element)
                response.put('response_x', new Wrike_MetadataService.deployResponse_element());
            else if(request instanceof Wrike_MetadataService.updateMetadata_element)
                response.put('response_x', new Wrike_MetadataService.updateMetadataResponse_element());
            else if(request instanceof Wrike_MetadataService.renameMetadata_element)
                response.put('response_x', new Wrike_MetadataService.renameMetadataResponse_element());
            else if(request instanceof  Wrike_MetadataService.cancelDeploy_element)
                response.put('response_x', new Wrike_MetadataService.cancelDeployResponse_element());
            else if(request instanceof  Wrike_MetadataService.deleteMetadata_element)
                response.put('response_x', new Wrike_MetadataService.deleteMetadataResponse_element());
            else if(request instanceof  Wrike_MetadataService.upsertMetadata_element)
                response.put('response_x', new Wrike_MetadataService.upsertMetadataResponse_element());
            else if(request instanceof  Wrike_MetadataService.createMetadata_element)
                response.put('response_x', new Wrike_MetadataService.createMetadataResponse_element());
            return;
        }
    }    
        
    @IsTest
    private static void coverGeneratedCodeCRUDOperations()
    {    
        // Null Web Service mock implementation
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        // Only required to workaround a current code coverage bug in the platform
        Wrike_MetadataService metaService = new Wrike_MetadataService();
        // Invoke operations         
        Wrike_MetadataService.MetadataPort metaDataPort = new Wrike_MetadataService.MetadataPort();
    }
    
    @IsTest
    private static void coverGeneratedCodeFileBasedOperations1()
    {        
        // Null Web Service mock implementation
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        // Only required to workaround a current code coverage bug in the platform
        Wrike_MetadataService metaService = new Wrike_MetadataService();
        // Invoke operations         
        Wrike_MetadataService.MetadataPort metaDataPort = new Wrike_MetadataService.MetadataPort();
        metaDataPort.retrieve(null);
        metaDataPort.checkDeployStatus(null, false);
        metaDataPort.listMetadata(null, null);
        metaDataPort.describeMetadata(null);
        metaDataPort.checkRetrieveStatus(null);
        metaDataPort.deploy(null, null);
        metaDataPort.checkDeployStatus(null, false);
        metaDataPort.updateMetadata(null);
        metaDataPort.renameMetadata(null, null, null);
        metaDataPort.cancelDeploy(null);
    }

    @IsTest
    private static void coverGeneratedCodeFileBasedOperations2()
    {       
        // Null Web Service mock implementation
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        // Only required to workaround a current code coverage bug in the platform
        Wrike_MetadataService metaService = new Wrike_MetadataService();
        // Invoke operations         
        Wrike_MetadataService.MetadataPort metaDataPort = new Wrike_MetadataService.MetadataPort();
        metaDataPort.deleteMetadata(null, null);
        metaDataPort.upsertMetadata(null);
        metaDataPort.createMetadata(null);
    }
        
    @IsTest
    private static void coverGeneratedCodeTypes()
    {               
        // Reference types
        new Wrike_MetadataService();
        new Wrike_MetadataService.listMetadataResponse_element();
        new Wrike_MetadataService.WorkflowRule();
        new Wrike_MetadataService.AccountOwnerSharingRule();
        new Wrike_MetadataService.RecordTypeTranslation();
        new Wrike_MetadataService.checkDeployStatus_element();
        new Wrike_MetadataService.CodeCoverageWarning();
        new Wrike_MetadataService.FlowApexPluginCall();
        new Wrike_MetadataService.FlowInputValidationRule();
        new Wrike_MetadataService.FlowFormula();
        new Wrike_MetadataService.CustomObjectCriteriaBasedSharingRule();
        new Wrike_MetadataService.PasswordPolicies();
        new Wrike_MetadataService.QueueSobject();
        new Wrike_MetadataService.CaseSharingRules();
        new Wrike_MetadataService.PicklistValueTranslation();
        new Wrike_MetadataService.OpportunityOwnerSharingRule();
        new Wrike_MetadataService.ContactOwnerSharingRule();
        new Wrike_MetadataService.CustomDataType();
        new Wrike_MetadataService.PrimaryTabComponents();
        new Wrike_MetadataService.WorkflowEmailRecipient();
        new Wrike_MetadataService.DescribeMetadataResult();
        new Wrike_MetadataService.RecordType();
        new Wrike_MetadataService.Scontrol();
        new Wrike_MetadataService.DashboardComponent();
        new Wrike_MetadataService.ContactCriteriaBasedSharingRule();
        new Wrike_MetadataService.FilterItem();
        new Wrike_MetadataService.Profile();
        new Wrike_MetadataService.ReportFilter();
        new Wrike_MetadataService.PermissionSetApexClassAccess();
        new Wrike_MetadataService.LogInfo();
        new Wrike_MetadataService.Layout();
        new Wrike_MetadataService.WebLink();
        new Wrike_MetadataService.WorkflowTaskTranslation();
        new Wrike_MetadataService.FlowElement();
        new Wrike_MetadataService.ObjectNameCaseValue();
        new Wrike_MetadataService.FlowInputFieldAssignment();
        new Wrike_MetadataService.CustomDataTypeTranslation();
        new Wrike_MetadataService.DashboardComponentSection();
        new Wrike_MetadataService.ReportTypeColumn();
        new Wrike_MetadataService.CallOptions_element();
        new Wrike_MetadataService.CustomObjectOwnerSharingRule();
        new Wrike_MetadataService.CustomFieldTranslation();
        new Wrike_MetadataService.AnalyticSnapshot();
        new Wrike_MetadataService.FlowRule();
        new Wrike_MetadataService.FlowRecordUpdate();
        new Wrike_MetadataService.CustomSite();
        new Wrike_MetadataService.ReportBlockInfo();
        new Wrike_MetadataService.describeMetadataResponse_element();
        new Wrike_MetadataService.CaseOwnerSharingRule();
        new Wrike_MetadataService.ScontrolTranslation();
        new Wrike_MetadataService.DeployMessage();
        new Wrike_MetadataService.FlowSubflowInputAssignment();
        new Wrike_MetadataService.Group_x();
        new Wrike_MetadataService.ReportColumn();
        new Wrike_MetadataService.ReportType();
        new Wrike_MetadataService.CustomPageWebLink();
        new Wrike_MetadataService.CodeCoverageResult();
        new Wrike_MetadataService.ApexComponent();
        new Wrike_MetadataService.BaseSharingRule();
        new Wrike_MetadataService.WorkflowKnowledgePublish();
        new Wrike_MetadataService.NetworkAccess();
        new Wrike_MetadataService.Workflow();
        new Wrike_MetadataService.RecordTypePicklistValue();
        new Wrike_MetadataService.describeMetadata_element();
        new Wrike_MetadataService.DashboardFilterColumn();
        new Wrike_MetadataService.FlowChoice();
        new Wrike_MetadataService.ReportParam();
        new Wrike_MetadataService.RoleOrTerritory();
        new Wrike_MetadataService.FlowStep();
        new Wrike_MetadataService.FlowApexPluginCallInputParameter();
        new Wrike_MetadataService.WorkflowActionReference();
        new Wrike_MetadataService.ProfileObjectPermissions();
        new Wrike_MetadataService.Role();
        new Wrike_MetadataService.RetrieveResult();
        new Wrike_MetadataService.SecuritySettings();
        new Wrike_MetadataService.WorkflowTimeTrigger();
        new Wrike_MetadataService.CustomObjectSharingRules();
        new Wrike_MetadataService.retrieve_element();
        new Wrike_MetadataService.DescribeMetadataObject();
        new Wrike_MetadataService.DashboardFilterOption();
        new Wrike_MetadataService.LayoutColumn();
        new Wrike_MetadataService.WorkflowOutboundMessage();
        new Wrike_MetadataService.RunTestSuccess();
        new Wrike_MetadataService.Queue();
        new Wrike_MetadataService.LeadSharingRules();
        new Wrike_MetadataService.ListViewFilter();
        new Wrike_MetadataService.CampaignOwnerSharingRule();
        new Wrike_MetadataService.CustomField();
        new Wrike_MetadataService.WorkflowTask();
        new Wrike_MetadataService.deployResponse_element();
        new Wrike_MetadataService.DataCategory();
        new Wrike_MetadataService.FlowOutputFieldAssignment();
        new Wrike_MetadataService.EmailTemplate();
        new Wrike_MetadataService.ReportAggregateReference();
        new Wrike_MetadataService.ObjectUsage();
        new Wrike_MetadataService.FileProperties();
        new Wrike_MetadataService.CustomTabTranslation();
        new Wrike_MetadataService.BusinessProcess();
        new Wrike_MetadataService.Flow();
        new Wrike_MetadataService.PermissionSet();
        new Wrike_MetadataService.PermissionSetObjectPermissions();
        new Wrike_MetadataService.ReportCrossFilter();
        new Wrike_MetadataService.Report();
        new Wrike_MetadataService.FlowSubflowOutputAssignment();
        new Wrike_MetadataService.ListView();
        new Wrike_MetadataService.FlowRecordCreate();
        new Wrike_MetadataService.DashboardTableColumn();
        new Wrike_MetadataService.ContactSharingRules();
        new Wrike_MetadataService.AccountTerritorySharingRules();
        new Wrike_MetadataService.AsyncResult();
        new Wrike_MetadataService.ArticleTypeChannelDisplay();
        new Wrike_MetadataService.checkRetrieveStatus_element();
        new Wrike_MetadataService.ProfileLayoutAssignment();
        new Wrike_MetadataService.ReportFolder();
        new Wrike_MetadataService.FlowTextTemplate();
        new Wrike_MetadataService.RelatedListItem();
        new Wrike_MetadataService.FlowNode();
        new Wrike_MetadataService.RetrieveRequest();
        new Wrike_MetadataService.ListMetadataQuery();
        new Wrike_MetadataService.FlowConnector();
        new Wrike_MetadataService.CustomApplicationComponent();
        new Wrike_MetadataService.FlowRecordLookup();
        new Wrike_MetadataService.FieldSet();
        new Wrike_MetadataService.ProfileApexClassAccess();
        new Wrike_MetadataService.AccountCriteriaBasedSharingRule();
        new Wrike_MetadataService.DebuggingHeader_element();
        new Wrike_MetadataService.CustomDataTypeComponentTranslation();
        new Wrike_MetadataService.FlowRecordDelete();
        new Wrike_MetadataService.FlowDecision();
        new Wrike_MetadataService.ReportTypeSectionTranslation();
        new Wrike_MetadataService.IpRange();
        new Wrike_MetadataService.FlowApexPluginCallOutputParameter();
        new Wrike_MetadataService.ReportBucketField();
        new Wrike_MetadataService.CaseCriteriaBasedSharingRule();
        new Wrike_MetadataService.CustomLabel();
        new Wrike_MetadataService.Attachment();
        new Wrike_MetadataService.SharingRules();
        new Wrike_MetadataService.CustomConsoleComponents();
        new Wrike_MetadataService.Portal();
        new Wrike_MetadataService.DomainWhitelist();
        new Wrike_MetadataService.ChartSummary();
        new Wrike_MetadataService.RunTestFailure();
        new Wrike_MetadataService.Territory();
        new Wrike_MetadataService.SharedTo();
        new Wrike_MetadataService.FlowRecordFilter();
        new Wrike_MetadataService.SubtabComponents();
        new Wrike_MetadataService.FlowScreen();
        new Wrike_MetadataService.WorkflowAlert();
        new Wrike_MetadataService.Picklist();
        new Wrike_MetadataService.ReportLayoutSection();
        new Wrike_MetadataService.SummaryLayoutItem();
        new Wrike_MetadataService.LayoutSection();
        new Wrike_MetadataService.ReportTimeFrameFilter();
        new Wrike_MetadataService.LayoutSectionTranslation();
        new Wrike_MetadataService.DataCategoryGroup();
        new Wrike_MetadataService.listMetadata_element();
        new Wrike_MetadataService.ValidationRule();
        new Wrike_MetadataService.WorkspaceMapping();
        new Wrike_MetadataService.MetadataWithContent();
        new Wrike_MetadataService.ValidationRuleTranslation();
        new Wrike_MetadataService.AccountTerritorySharingRule();
        new Wrike_MetadataService.Metadata();
        new Wrike_MetadataService.ReportBucketFieldValue();
        new Wrike_MetadataService.OpportunitySharingRules();
        new Wrike_MetadataService.HomePageLayout();
        new Wrike_MetadataService.FlowSubflow();
        new Wrike_MetadataService.FlowScreenField();
        new Wrike_MetadataService.SiteWebAddress();
        new Wrike_MetadataService.RetrieveMessage();
        new Wrike_MetadataService.Dashboard();
        new Wrike_MetadataService.EmailFolder();
        new Wrike_MetadataService.SessionHeader_element();
        new Wrike_MetadataService.SummaryLayout();
        new Wrike_MetadataService.FlowCondition();
        new Wrike_MetadataService.DeployOptions();
        new Wrike_MetadataService.FlowAssignment();
        new Wrike_MetadataService.ProfileApplicationVisibility();
        new Wrike_MetadataService.UpdateMetadata();
        new Wrike_MetadataService.CustomApplicationComponents();
        new Wrike_MetadataService.FlowElementReferenceOrValue();
        new Wrike_MetadataService.EntitlementTemplate();
        new Wrike_MetadataService.ProfileTabVisibility();
        new Wrike_MetadataService.ActionOverride();
        new Wrike_MetadataService.WorkspaceMappings();
        new Wrike_MetadataService.WorkflowAction();
        new Wrike_MetadataService.DashboardFolder();
        new Wrike_MetadataService.PermissionSetApexPageAccess();
        new Wrike_MetadataService.LayoutTranslation();
        new Wrike_MetadataService.CustomObject();
        new Wrike_MetadataService.Translations();
        new Wrike_MetadataService.ApexTrigger();
        new Wrike_MetadataService.ReportTypeTranslation();
        new Wrike_MetadataService.FlowAssignmentItem();
        new Wrike_MetadataService.CustomApplicationTranslation();
        new Wrike_MetadataService.CustomLabels();
        new Wrike_MetadataService.PackageTypeMembers();
        new Wrike_MetadataService.PicklistValue();
        new Wrike_MetadataService.RemoteSiteSetting();
        new Wrike_MetadataService.deploy_element();
        new Wrike_MetadataService.retrieveResponse_element();
        new Wrike_MetadataService.ArticleTypeTemplate();
        new Wrike_MetadataService.ReportGrouping();
        new Wrike_MetadataService.PermissionSetFieldPermissions();
        new Wrike_MetadataService.AnalyticSnapshotMapping();
        new Wrike_MetadataService.LeadCriteriaBasedSharingRule();
        new Wrike_MetadataService.SharingRecalculation();
        new Wrike_MetadataService.ProfileLoginIpRange();
        new Wrike_MetadataService.WebLinkTranslation();
        new Wrike_MetadataService.ObjectRelationship();
        new Wrike_MetadataService.ListPlacement();
        new Wrike_MetadataService.SiteRedirectMapping();
        new Wrike_MetadataService.OwnerSharingRule();
        new Wrike_MetadataService.WorkflowFieldUpdate();
        new Wrike_MetadataService.LetterheadLine();
        new Wrike_MetadataService.OpportunityCriteriaBasedSharingRule();
        new Wrike_MetadataService.CustomTab();
        new Wrike_MetadataService.FlowChoiceUserInput();
        new Wrike_MetadataService.Letterhead();
        new Wrike_MetadataService.ReportTypeColumnTranslation();
        new Wrike_MetadataService.CustomPageWebLinkTranslation();
        new Wrike_MetadataService.DocumentFolder();
        new Wrike_MetadataService.FlowConstant();
        new Wrike_MetadataService.ProfileRecordTypeVisibility();
        new Wrike_MetadataService.PackageVersion();
        new Wrike_MetadataService.CustomLabelTranslation();
        new Wrike_MetadataService.ReportChart();
        new Wrike_MetadataService.checkRetrieveStatusResponse_element();
        new Wrike_MetadataService.LeadOwnerSharingRule();
        new Wrike_MetadataService.ProfileFieldLevelSecurity();
        new Wrike_MetadataService.SharingReason();
        new Wrike_MetadataService.RunTestsResult();
        new Wrike_MetadataService.PermissionSetUserPermission();
        new Wrike_MetadataService.MiniLayout();
        new Wrike_MetadataService.FlowVariable();
        new Wrike_MetadataService.ProfileLoginHours();
        new Wrike_MetadataService.DashboardFilter();
        new Wrike_MetadataService.CodeLocation();
        new Wrike_MetadataService.ReportBucketFieldSourceValue();
        new Wrike_MetadataService.FieldSetItem();
        new Wrike_MetadataService.ReportFilterItem();
        new Wrike_MetadataService.FlowDynamicChoiceSet();
        new Wrike_MetadataService.CustomDataTypeComponent();
        new Wrike_MetadataService.CustomObjectTranslation();
        new Wrike_MetadataService.CustomApplication();
        new Wrike_MetadataService.ReportAggregate();
        new Wrike_MetadataService.ApexClass();
        new Wrike_MetadataService.CampaignSharingRules();
        new Wrike_MetadataService.DebuggingInfo_element();
        new Wrike_MetadataService.Package_x();
        new Wrike_MetadataService.SessionSettings();
        new Wrike_MetadataService.Document();
        new Wrike_MetadataService.Folder();
        new Wrike_MetadataService.DeployResult();
        new Wrike_MetadataService.CampaignCriteriaBasedSharingRule();
        new Wrike_MetadataService.LayoutItem();
        new Wrike_MetadataService.ProfileApexPageAccess();
        new Wrike_MetadataService.SharingReasonTranslation();
        new Wrike_MetadataService.checkDeployStatusResponse_element();
        new Wrike_MetadataService.ReportColorRange();
        new Wrike_MetadataService.SearchLayouts();
        new Wrike_MetadataService.LetterheadHeaderFooter();
        new Wrike_MetadataService.HomePageComponent();
        new Wrike_MetadataService.AccountSharingRules();
        new Wrike_MetadataService.MobileSettings();
        new Wrike_MetadataService.EscalationRules();
        new Wrike_MetadataService.KnowledgeAnswerSettings();
        new Wrike_MetadataService.ExternalDataSource();
        new Wrike_MetadataService.EntitlementProcess();
        new Wrike_MetadataService.IdeasSettings();
        new Wrike_MetadataService.Country();
        new Wrike_MetadataService.ReputationLevels();
        new Wrike_MetadataService.KnowledgeSitesSettings();
        new Wrike_MetadataService.AddressSettings();
        new Wrike_MetadataService.ProfileExternalDataSourceAccess();
        new Wrike_MetadataService.CallCenterItem();
        new Wrike_MetadataService.CallCenter();
        new Wrike_MetadataService.PermissionSetExternalDataSourceAccess();
        new Wrike_MetadataService.PermissionSetTabSetting();
        new Wrike_MetadataService.AuthProvider();
        new Wrike_MetadataService.EmailToCaseSettings();
        new Wrike_MetadataService.EscalationAction();
        new Wrike_MetadataService.State();
        new Wrike_MetadataService.AssignmentRule();
        new Wrike_MetadataService.AutoResponseRule();
        new Wrike_MetadataService.CaseSettings();
        new Wrike_MetadataService.ChatterAnswersSettings();
        new Wrike_MetadataService.CountriesAndStates();
        new Wrike_MetadataService.SFDCMobileSettings();
        new Wrike_MetadataService.EntitlementProcessMilestoneItem();
        new Wrike_MetadataService.TouchMobileSettings();
        new Wrike_MetadataService.AssignmentRules();
        new Wrike_MetadataService.ContractSettings();
        new Wrike_MetadataService.KnowledgeCaseSettings();
        new Wrike_MetadataService.ChatterAnswersReputationLevel();
        new Wrike_MetadataService.KnowledgeSettings();
        new Wrike_MetadataService.Community();
        new Wrike_MetadataService.AutoResponseRules();
        new Wrike_MetadataService.EmailToCaseRoutingAddress();
        new Wrike_MetadataService.RuleEntry();
        new Wrike_MetadataService.EntitlementSettings();
        new Wrike_MetadataService.CriteriaBasedSharingRule();
        new Wrike_MetadataService.ApexPage();
        new Wrike_MetadataService.WorkflowSend();
        new Wrike_MetadataService.ChatterMobileSettings();
        new Wrike_MetadataService.CallCenterSection();
        new Wrike_MetadataService.EntitlementProcessMilestoneTimeTrigger();
        new Wrike_MetadataService.StaticResource();
        new Wrike_MetadataService.MilestoneType();
        new Wrike_MetadataService.FiscalYearSettings();
        new Wrike_MetadataService.CompanySettings();
        new Wrike_MetadataService.WebToCaseSettings();
        new Wrike_MetadataService.EscalationRule();
        new Wrike_MetadataService.DashboardMobileSettings();
        new Wrike_MetadataService.FieldOverride();
        new Wrike_MetadataService.QuotasSettings();
        new Wrike_MetadataService.Skill();
        new Wrike_MetadataService.AgentConfigProfileAssignments();
        new Wrike_MetadataService.LiveAgentSettings();
        new Wrike_MetadataService.SkillAssignments();
        new Wrike_MetadataService.ActivitiesSettings();
        new Wrike_MetadataService.LiveAgentConfig();
        new Wrike_MetadataService.ApprovalPageField();
        new Wrike_MetadataService.QuickActionList();
        new Wrike_MetadataService.LiveChatButtonDeployments();
        new Wrike_MetadataService.InstalledPackage();
        new Wrike_MetadataService.PushNotification();
        new Wrike_MetadataService.LiveChatAgentConfig();
        new Wrike_MetadataService.AdjustmentsSettings();                               
        new Wrike_MetadataService.ForecastingSettings();                                
        new Wrike_MetadataService.QuickActionListItem();           
        new Wrike_MetadataService.Branding();          
        new Wrike_MetadataService.QuickActionLayoutItem();                     
        new Wrike_MetadataService.OpportunityListFieldsSelectedSettings();        
        new Wrike_MetadataService.ApprovalStepRejectBehavior();
        new Wrike_MetadataService.FolderShare();   
        new Wrike_MetadataService.ApprovalEntryCriteria();                                
        new Wrike_MetadataService.ProductSettings();                                
        new Wrike_MetadataService.OpportunitySettings();              
        new Wrike_MetadataService.LiveChatDeployment();                                
        new Wrike_MetadataService.QuickActionLayoutColumn();           
        new Wrike_MetadataService.GlobalQuickActionTranslation();      
        new Wrike_MetadataService.ApprovalStepApprover();                                
        new Wrike_MetadataService.QuoteSettings();         
        new Wrike_MetadataService.LiveChatButton();                                
        new Wrike_MetadataService.Network();
        new Wrike_MetadataService.LiveChatDeploymentDomainWhitelist();
        new Wrike_MetadataService.KnowledgeLanguageSettings();
        new Wrike_MetadataService.Approver();
        new Wrike_MetadataService.SamlSsoConfig();
        new Wrike_MetadataService.ApprovalSubmitter();
        new Wrike_MetadataService.KeyboardShortcuts();
        new Wrike_MetadataService.ApprovalStep();
        new Wrike_MetadataService.AgentConfigAssignments();
        new Wrike_MetadataService.QuickAction();
        new Wrike_MetadataService.DefaultShortcut();
        new Wrike_MetadataService.ApprovalAction();
        new Wrike_MetadataService.KnowledgeLanguage();
        new Wrike_MetadataService.LiveChatButtonSkills();
        new Wrike_MetadataService.SkillUserAssignments();
        new Wrike_MetadataService.NextAutomatedApprover();
        new Wrike_MetadataService.ApprovalProcess();
        new Wrike_MetadataService.QuickActionLayout();
        new Wrike_MetadataService.PushNotifications();
        new Wrike_MetadataService.ForecastRangeSettings();
        new Wrike_MetadataService.IdeaReputationLevel();
        new Wrike_MetadataService.NetworkTabSet();
        new Wrike_MetadataService.SkillProfileAssignments();
        new Wrike_MetadataService.CustomShortcut();
        new Wrike_MetadataService.PagesToOpen();
        new Wrike_MetadataService.AgentConfigUserAssignments();
        new Wrike_MetadataService.NetworkMemberGroup();
        new Wrike_MetadataService.FindSimilarOppFilter();
        new Wrike_MetadataService.QuickActionTranslation();                
        new Wrike_MetadataService.WorkflowFlowActionParameter();
        new Wrike_MetadataService.ConnectedAppOauthConfig();
        new Wrike_MetadataService.FlowLoop();
        new Wrike_MetadataService.UserSharingRules();
        new Wrike_MetadataService.renameMetadata_element();
        new Wrike_MetadataService.ForecastingTypeSettings();
        new Wrike_MetadataService.PermissionSetApplicationVisibility();
        new Wrike_MetadataService.FeedLayout();
        new Wrike_MetadataService.AppMenuItem();
        new Wrike_MetadataService.deleteMetadataResponse_element();
        new Wrike_MetadataService.ConnectedAppAttribute();
        new Wrike_MetadataService.ReportChartComponentLayoutItem();
        new Wrike_MetadataService.AppMenu();
        new Wrike_MetadataService.ConnectedAppIpRange();
        new Wrike_MetadataService.Error();
        new Wrike_MetadataService.ComponentInstanceProperty();
        new Wrike_MetadataService.BusinessHoursEntry();
        new Wrike_MetadataService.RelatedContent();
        new Wrike_MetadataService.SupervisorAgentConfigSkills();
        new Wrike_MetadataService.ComponentInstance();
        new Wrike_MetadataService.SidebarComponent();
        new Wrike_MetadataService.Holiday();
        new Wrike_MetadataService.SaveResult();
        new Wrike_MetadataService.readMetadataResponse_element();
        new Wrike_MetadataService.FlexiPageRegion();
        new Wrike_MetadataService.deleteMetadata_element();
        new Wrike_MetadataService.ConnectedAppMobileDetailConfig();
        new Wrike_MetadataService.AccountSettings();
        new Wrike_MetadataService.PermissionSetRecordTypeVisibility();
        new Wrike_MetadataService.OrderSettings();
        new Wrike_MetadataService.ProfileUserPermission();
        new Wrike_MetadataService.UserCriteriaBasedSharingRule();
        new Wrike_MetadataService.LookupFilterTranslation();
        new Wrike_MetadataService.WorkflowFlowAction();
        new Wrike_MetadataService.ConnectedApp();
        new Wrike_MetadataService.SiteDotCom();
        new Wrike_MetadataService.createMetadataResponse_element();
        new Wrike_MetadataService.updateMetadata_element();
        new Wrike_MetadataService.LookupFilter();
        new Wrike_MetadataService.updateMetadataResponse_element();
        new Wrike_MetadataService.FlexiPage();
        new Wrike_MetadataService.ConnectedAppSamlConfig();
        new Wrike_MetadataService.createMetadata_element();
        new Wrike_MetadataService.FeedLayoutComponent();
        new Wrike_MetadataService.PostTemplate();
        new Wrike_MetadataService.RelatedContentItem();
        new Wrike_MetadataService.readMetadata_element();
        new Wrike_MetadataService.ReadWorkflowRuleResult();
        new Wrike_MetadataService.readWorkflowRuleResponse_element();
        new Wrike_MetadataService.ReadSamlSsoConfigResult();
        new Wrike_MetadataService.readSamlSsoConfigResponse_element();
        new Wrike_MetadataService.ReadCustomLabelResult();
        new Wrike_MetadataService.readCustomLabelResponse_element();
        new Wrike_MetadataService.ReadBusinessHoursEntryResult();
        new Wrike_MetadataService.readBusinessHoursEntryResponse_element();
        new Wrike_MetadataService.ReadMobileSettingsResult();
        new Wrike_MetadataService.readMobileSettingsResponse_element();
        new Wrike_MetadataService.ReadChatterAnswersSettingsResult();
        new Wrike_MetadataService.readChatterAnswersSettingsResponse_element();
        new Wrike_MetadataService.ReadSharingRulesResult();
        new Wrike_MetadataService.readSharingRulesResponse_element();
        new Wrike_MetadataService.ReadPortalResult();
        new Wrike_MetadataService.readPortalResponse_element();
        new Wrike_MetadataService.ReadSkillResult();
        new Wrike_MetadataService.readSkillResponse_element();
        new Wrike_MetadataService.ReadEscalationRulesResult();
        new Wrike_MetadataService.readEscalationRulesResponse_element();
        new Wrike_MetadataService.ReadCustomDataTypeResult();
        new Wrike_MetadataService.readCustomDataTypeResponse_element();
        new Wrike_MetadataService.ReadExternalDataSourceResult();
        new Wrike_MetadataService.readExternalDataSourceResponse_element();
        new Wrike_MetadataService.ReadEntitlementProcessResult();
        new Wrike_MetadataService.readEntitlementProcessResponse_element();
        new Wrike_MetadataService.ReadRecordTypeResult();
        new Wrike_MetadataService.readRecordTypeResponse_element();
        new Wrike_MetadataService.ReadScontrolResult();
        new Wrike_MetadataService.readScontrolResponse_element();
        new Wrike_MetadataService.ReadDataCategoryGroupResult();
        new Wrike_MetadataService.readDataCategoryGroupResponse_element();
        new Wrike_MetadataService.ReadValidationRuleResult();
        new Wrike_MetadataService.readValidationRuleResponse_element();
        new Wrike_MetadataService.ReadProfileResult();
        new Wrike_MetadataService.readProfileResponse_element();
        new Wrike_MetadataService.ReadIdeasSettingsResult();
        new Wrike_MetadataService.readIdeasSettingsResponse_element();
        new Wrike_MetadataService.ReadConnectedAppResult();
        new Wrike_MetadataService.readConnectedAppResponse_element();
        new Wrike_MetadataService.ReadApexPageResult();
        new Wrike_MetadataService.readApexPageResponse_element();
        new Wrike_MetadataService.ReadProductSettingsResult();
        new Wrike_MetadataService.readProductSettingsResponse_element();
        new Wrike_MetadataService.ReadLiveAgentSettingsResult();
        new Wrike_MetadataService.readLiveAgentSettingsResponse_element();
        new Wrike_MetadataService.ReadOpportunitySettingsResult();
        new Wrike_MetadataService.readOpportunitySettingsResponse_element();
        new Wrike_MetadataService.ReadLiveChatDeploymentResult();
        new Wrike_MetadataService.readLiveChatDeploymentResponse_element();
        new Wrike_MetadataService.ReadActivitiesSettingsResult();
        new Wrike_MetadataService.readActivitiesSettingsResponse_element();
        new Wrike_MetadataService.ReadLayoutResult();
        new Wrike_MetadataService.readLayoutResponse_element();
        new Wrike_MetadataService.ReadWebLinkResult();
        new Wrike_MetadataService.readWebLinkResponse_element();
        new Wrike_MetadataService.ReadSiteDotComResult();
        new Wrike_MetadataService.readSiteDotComResponse_element();
        new Wrike_MetadataService.ReadCompanySettingsResult();
        new Wrike_MetadataService.readCompanySettingsResponse_element();
        new Wrike_MetadataService.ReadHomePageLayoutResult();
        new Wrike_MetadataService.readHomePageLayoutResponse_element();
        new Wrike_MetadataService.ReadDashboardResult();
        new Wrike_MetadataService.readDashboardResponse_element();
        new Wrike_MetadataService.ReadAssignmentRulesResult();
        new Wrike_MetadataService.readAssignmentRulesResponse_element();
        new Wrike_MetadataService.ReadAnalyticSnapshotResult();
        new Wrike_MetadataService.readAnalyticSnapshotResponse_element();
        new Wrike_MetadataService.ReadEscalationRuleResult();
        new Wrike_MetadataService.readEscalationRuleResponse_element();
        new Wrike_MetadataService.ReadCustomSiteResult();
        new Wrike_MetadataService.readCustomSiteResponse_element();
        new Wrike_MetadataService.ReadGroupResult();
        new Wrike_MetadataService.readGroupResponse_element();
        new Wrike_MetadataService.ReadReportTypeResult();
        new Wrike_MetadataService.readReportTypeResponse_element();
        new Wrike_MetadataService.ReadQuickActionResult();
        new Wrike_MetadataService.readQuickActionResponse_element();
        new Wrike_MetadataService.ReadCustomPageWebLinkResult();
        new Wrike_MetadataService.readCustomPageWebLinkResponse_element();
        new Wrike_MetadataService.ReadApexComponentResult();
        new Wrike_MetadataService.readApexComponentResponse_element();
        new Wrike_MetadataService.ReadBaseSharingRuleResult();
        new Wrike_MetadataService.readBaseSharingRuleResponse_element();
        new Wrike_MetadataService.ReadEntitlementTemplateResult();
        new Wrike_MetadataService.readEntitlementTemplateResponse_element();
        new Wrike_MetadataService.ReadFlexiPageResult();
        new Wrike_MetadataService.readFlexiPageResponse_element();
        new Wrike_MetadataService.ReadWorkflowResult();
        new Wrike_MetadataService.readWorkflowResponse_element();
        new Wrike_MetadataService.ReadWorkflowActionResult();
        new Wrike_MetadataService.readWorkflowActionResponse_element();
        new Wrike_MetadataService.ReadAddressSettingsResult();
        new Wrike_MetadataService.readAddressSettingsResponse_element();
        new Wrike_MetadataService.ReadContractSettingsResult();
        new Wrike_MetadataService.readContractSettingsResponse_element();
        new Wrike_MetadataService.ReadCustomObjectResult();
        new Wrike_MetadataService.readCustomObjectResponse_element();
        new Wrike_MetadataService.ReadTranslationsResult();
        new Wrike_MetadataService.readTranslationsResponse_element();
        new Wrike_MetadataService.ReadRoleOrTerritoryResult();
        new Wrike_MetadataService.readRoleOrTerritoryResponse_element();
        new Wrike_MetadataService.ReadApexTriggerResult();
        new Wrike_MetadataService.readApexTriggerResponse_element();
        new Wrike_MetadataService.ReadCustomLabelsResult();
        new Wrike_MetadataService.readCustomLabelsResponse_element();
        new Wrike_MetadataService.ReadSecuritySettingsResult();
        new Wrike_MetadataService.readSecuritySettingsResponse_element();
        new Wrike_MetadataService.ReadCallCenterResult();
        new Wrike_MetadataService.readCallCenterResponse_element();
        new Wrike_MetadataService.ReadPicklistValueResult();
        new Wrike_MetadataService.readPicklistValueResponse_element();
        new Wrike_MetadataService.ReadRemoteSiteSettingResult();
        new Wrike_MetadataService.readRemoteSiteSettingResponse_element();
        new Wrike_MetadataService.ReadQuoteSettingsResult();
        new Wrike_MetadataService.readQuoteSettingsResponse_element();
        new Wrike_MetadataService.ReadSynonymDictionaryResult();
        new Wrike_MetadataService.readSynonymDictionaryResponse_element();
        new Wrike_MetadataService.ReadPostTemplateResult();
        new Wrike_MetadataService.readPostTemplateResponse_element();
        new Wrike_MetadataService.ReadCustomTabResult();
        new Wrike_MetadataService.readCustomTabResponse_element();
        new Wrike_MetadataService.ReadLetterheadResult();
        new Wrike_MetadataService.readLetterheadResponse_element();
        new Wrike_MetadataService.ReadInstalledPackageResult();
        new Wrike_MetadataService.readInstalledPackageResponse_element();
        new Wrike_MetadataService.ReadQueueResult();
        new Wrike_MetadataService.readQueueResponse_element();
        new Wrike_MetadataService.ReadAuthProviderResult();
        new Wrike_MetadataService.readAuthProviderResponse_element();
        new Wrike_MetadataService.ReadEntitlementSettingsResult();
        new Wrike_MetadataService.readEntitlementSettingsResponse_element();
        new Wrike_MetadataService.ReadCustomFieldResult();
        new Wrike_MetadataService.readCustomFieldResponse_element();
        new Wrike_MetadataService.ReadStaticResourceResult();
        new Wrike_MetadataService.readStaticResourceResponse_element();
        new Wrike_MetadataService.ReadEmailTemplateResult();
        new Wrike_MetadataService.readEmailTemplateResponse_element();
        new Wrike_MetadataService.ReadSharingReasonResult();
        new Wrike_MetadataService.readSharingReasonResponse_element();
        new Wrike_MetadataService.ReadLiveChatButtonResult();
        new Wrike_MetadataService.readLiveChatButtonResponse_element();
        new Wrike_MetadataService.ReadNetworkResult();
        new Wrike_MetadataService.readNetworkResponse_element();
        new Wrike_MetadataService.ReadApprovalProcessResult();
        new Wrike_MetadataService.readApprovalProcessResponse_element();
        new Wrike_MetadataService.ReadMilestoneTypeResult();
        new Wrike_MetadataService.readMilestoneTypeResponse_element();
        new Wrike_MetadataService.ReadAssignmentRuleResult();
        new Wrike_MetadataService.readAssignmentRuleResponse_element();
        new Wrike_MetadataService.ReadCompactLayoutResult();
        new Wrike_MetadataService.readCompactLayoutResponse_element();
        new Wrike_MetadataService.ReadLiveChatAgentConfigResult();
        new Wrike_MetadataService.readLiveChatAgentConfigResponse_element();
        new Wrike_MetadataService.ReadAccountSettingsResult();
        new Wrike_MetadataService.readAccountSettingsResponse_element();
        new Wrike_MetadataService.ReadBusinessProcessResult();
        new Wrike_MetadataService.readBusinessProcessResponse_element();
        new Wrike_MetadataService.ReadFlowResult();
        new Wrike_MetadataService.readFlowResponse_element();
        new Wrike_MetadataService.ReadAutoResponseRuleResult();
        new Wrike_MetadataService.readAutoResponseRuleResponse_element();
        new Wrike_MetadataService.ReadPermissionSetResult();
        new Wrike_MetadataService.readPermissionSetResponse_element();
        new Wrike_MetadataService.ReadBusinessHoursSettingsResult();
        new Wrike_MetadataService.readBusinessHoursSettingsResponse_element();
        new Wrike_MetadataService.ReadForecastingSettingsResult();
        new Wrike_MetadataService.readForecastingSettingsResponse_element();
        new Wrike_MetadataService.ReadReportResult();
        new Wrike_MetadataService.readReportResponse_element();
        new Wrike_MetadataService.ReadAppMenuResult();
        new Wrike_MetadataService.readAppMenuResponse_element();
        new Wrike_MetadataService.ReadListViewResult();
        new Wrike_MetadataService.readListViewResponse_element();
        new Wrike_MetadataService.ReadOrderSettingsResult();
        new Wrike_MetadataService.readOrderSettingsResponse_element();
        new Wrike_MetadataService.ReadCustomObjectTranslationResult();
        new Wrike_MetadataService.readCustomObjectTranslationResponse_element();
        new Wrike_MetadataService.ReadCustomApplicationResult();
        new Wrike_MetadataService.readCustomApplicationResponse_element();
        new Wrike_MetadataService.ReadKnowledgeSettingsResult();
        new Wrike_MetadataService.readKnowledgeSettingsResponse_element();
        new Wrike_MetadataService.ReadCaseSettingsResult();
        new Wrike_MetadataService.readCaseSettingsResponse_element();
        new Wrike_MetadataService.ReadApexClassResult();
        new Wrike_MetadataService.readApexClassResponse_element();
        new Wrike_MetadataService.ReadPackageResult();
        new Wrike_MetadataService.readPackageResponse_element();
        new Wrike_MetadataService.ReadCommunityResult();
        new Wrike_MetadataService.readCommunityResponse_element();
        new Wrike_MetadataService.ReadDocumentResult();
        new Wrike_MetadataService.readDocumentResponse_element();
        new Wrike_MetadataService.ReadAutoResponseRulesResult();
        new Wrike_MetadataService.readAutoResponseRulesResponse_element();
        new Wrike_MetadataService.ReadFolderResult();
        new Wrike_MetadataService.readFolderResponse_element();
        new Wrike_MetadataService.ReadCustomApplicationComponentResult();
        new Wrike_MetadataService.readCustomApplicationComponentResponse_element();
        new Wrike_MetadataService.ReadFieldSetResult();
        new Wrike_MetadataService.readFieldSetResponse_element();
        new Wrike_MetadataService.ReadSharingSetResult();
        new Wrike_MetadataService.readSharingSetResponse_element();
        new Wrike_MetadataService.ReadHomePageComponentResult();
        new Wrike_MetadataService.readHomePageComponentResponse_element();
        new Wrike_MetadataService.ReadResult();
        new Wrike_MetadataService.UserMembershipSharingRule();
        new Wrike_MetadataService.BusinessHoursSettings();
        new Wrike_MetadataService.FeedLayoutFilter();
        new Wrike_MetadataService.ReportHistoricalSelector();
        new Wrike_MetadataService.ConnectedAppCanvasConfig();
        new Wrike_MetadataService.DeployDetails();
        new Wrike_MetadataService.ReportDataCategoryFilter();
        new Wrike_MetadataService.SynonymGroup();
        new Wrike_MetadataService.renameMetadataResponse_element();
        new Wrike_MetadataService.cancelDeploy_element();
        new Wrike_MetadataService.CancelDeployResult();
        new Wrike_MetadataService.SynonymDictionary();
        new Wrike_MetadataService.cancelDeployResponse_element();
        new Wrike_MetadataService.CompactLayout();
        new Wrike_MetadataService.AccessMapping();
        new Wrike_MetadataService.Container();
        new Wrike_MetadataService.DeleteResult();
        new Wrike_MetadataService.SharingSet();
        new Wrike_MetadataService.ReputationPointsRule();
        new Wrike_MetadataService.FlowActionCallInputParameter();
        new Wrike_MetadataService.CustomMetadata();
        new Wrike_MetadataService.VisualizationPlugin();
        new Wrike_MetadataService.RelatedList();
        new Wrike_MetadataService.FlowActionCallOutputParameter();
        new Wrike_MetadataService.FlowActionCall();
        new Wrike_MetadataService.CustomPermission();
        new Wrike_MetadataService.ReputationLevelDefinitions();
        new Wrike_MetadataService.PermissionSetCustomPermissions();
        new Wrike_MetadataService.upsertMetadata_element();
        new Wrike_MetadataService.ProfileCustomPermissions();
        new Wrike_MetadataService.AgentConfigButtons();
        new Wrike_MetadataService.AgentConfigSkills();
        new Wrike_MetadataService.upsertMetadataResponse_element();
        new Wrike_MetadataService.ReputationLevel();
        new Wrike_MetadataService.ReadWorkflowAlertResult();
        new Wrike_MetadataService.readWorkflowAlertResponse_element();
        new Wrike_MetadataService.ReadCustomPermissionResult();
        new Wrike_MetadataService.readCustomPermissionResponse_element();
        new Wrike_MetadataService.ReadSiteDotComResult();
        new Wrike_MetadataService.ReadEmailFolderResult();
        new Wrike_MetadataService.readEmailFolderResponse_element();
        new Wrike_MetadataService.ReadCustomMetadataResult();
        new Wrike_MetadataService.readCustomMetadataResponse_element();
        new Wrike_MetadataService.ReadAnalyticSnapshotResult();
        new Wrike_MetadataService.readAnalyticSnapshotResponse_element();
        new Wrike_MetadataService.ReadVisualizationPluginResult();
        new Wrike_MetadataService.readVisualizationPluginResponse_element();
        new Wrike_MetadataService.ReadEscalationRuleResult();
        new Wrike_MetadataService.ReadMarketingActionSettingsResult();
        new Wrike_MetadataService.readMarketingActionSettingsResponse_element();
        new Wrike_MetadataService.ReadWorkflowKnowledgePublishResult();
        new Wrike_MetadataService.readWorkflowKnowledgePublishResponse_element();
        new Wrike_MetadataService.ReadDashboardFolderResult();
        new Wrike_MetadataService.readDashboardFolderResponse_element();
        new Wrike_MetadataService.ReadWorkflowSendResult();
        new Wrike_MetadataService.readWorkflowSendResponse_element();
        new Wrike_MetadataService.ReadWorkflowOutboundMessageResult();
        new Wrike_MetadataService.readWorkflowOutboundMessageResponse_element();
        new Wrike_MetadataService.ReadWorkflowFieldUpdateResult();
        new Wrike_MetadataService.readWorkflowFieldUpdateResponse_element();
        new Wrike_MetadataService.ReadDocumentFolderResult();
        new Wrike_MetadataService.readDocumentFolderResponse_element();
        new Wrike_MetadataService.ReadWorkflowTaskResult();
        new Wrike_MetadataService.readWorkflowTaskResponse_element();
        new Wrike_MetadataService.ReadNameSettingsResult();
        new Wrike_MetadataService.readNameSettingsResponse_element();
        new Wrike_MetadataService.ReadReportFolderResult();
        new Wrike_MetadataService.readReportFolderResponse_element();
        new Wrike_MetadataService.ReadCustomApplicationComponentResult();
        new Wrike_MetadataService.NameSettings();
        new Wrike_MetadataService.ReputationPointsRules();
        new Wrike_MetadataService.FlowMetadataValue();
        new Wrike_MetadataService.VisualizationResource();
        new Wrike_MetadataService.MarketingActionSettings();
        new Wrike_MetadataService.VisualizationType();
        new Wrike_MetadataService.CustomMetadataValue();
        new Wrike_MetadataService.HistoryRetentionPolicy();
        new Wrike_MetadataService.UpsertResult();
    }
}