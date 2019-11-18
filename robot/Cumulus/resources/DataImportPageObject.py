from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from NPSP import npsp_lex_locators

@pageobject("Listing", "DataImport__c")
class DataImportPage(ListingPage):

    @property
    def npsp(self):
        return self.builtin.get_library_instance('NPSP')
    
    @property
    def pageobjects(self):
        return self.builtin.get_library_instance("cumulusci.robotframework.PageObjects")
    
    def _is_current_page(self):
        """
        Waits for the current page to be a Data Import list view
        """
        self.npsp.wait_until_url_contains("/list")
            
    def click(self,btn_name):
        """Clicks button with specified name on Data Import Page"""
        self.npsp.click_special_object_button(btn_name)
        
    def begin_data_import_process_and_verify_status(self,batch,status):
        """On the DI page, clicks the Begin Data Import Process button and waits for specified status to display """
        self.npsp.wait_for_locator("frame","NPSP Data Import")
        self.npsp.select_frame_and_click_element("NPSP Data Import","button","Begin Data Import Process")
        self.npsp.wait_for_batch_to_process(batch,status)
        
    def click_close_button(self):
        """Click on close button on DI processing page and waits for DI object homepage to load"""
        self.npsp.click_button_with_value("Close")
        self.npsp.wait_until_url_contains("DataImport__c")    
        
    def select_import_record(self,record_name):
        self.selenium.page_should_contain_link(record_name)
        locator=npsp_lex_locators['data_imports']['checkbox'].format(record_name) 
        self.selenium.click_element(locator)   
        
    def open_data_import_record(self,di_name): 
        """Clicks on the specified data import record to open the record""" 
        self.pageobjects.current_page_should_be("Listing","DataImport__c")
        self.npsp.click_link_with_text(di_name)
        self.pageobjects.current_page_should_be("Details","DataImport__c")
        
        
        
@pageobject("Details", "DataImport__c")
class DataImportDetailPage(DetailPage): 
    
    
    @property
    def npsp(self):
        return self.builtin.get_library_instance('NPSP')
           
        
    def edit_record(self):
        """From the actions dropdown select edit action and wait for modal to open"""
        locator=npsp_lex_locators['link-contains'].format("more actions")
        self.selenium.click_link(locator)
        dd=npsp_lex_locators['data_imports']['actions_dd']
        self.selenium.wait_until_page_contains_element(dd, error="Show more actions dropdown didn't open in 30 sec")
        self.selenium.click_link("Edit")
        self.salesforce.wait_until_modal_is_open()
        
    def select_value_from_dropdown(self,dropdown,value): 
        """Select given value in the dropdown field"""
        self.npsp.click_dropdown(dropdown)     
        self.selenium.click_link(value)    

    def save_record(self):
        """clicks the save button on the modal and waits till modal is closed"""
        self.salesforce.click_modal_button("Save")
        self.salesforce.wait_until_modal_is_closed()
