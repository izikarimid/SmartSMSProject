//
//  SMSNewSMSViewController.m
//  SMS Scheduler
//
// Created by ilabafrica on 24/08/2016.
// Copyright © 2016 Strathmore. All rights reserved.
//

#import "SMSNewSMSViewController.h"
#import <AddressBookUI/AddressBookUI.h>
#import <AddressBook/AddressBook.h>
#import "SMSManager.h"
#import "SMSColors.h"
#import "SMS.h"

@interface SMSNewSMSViewController () <ABPeoplePickerNavigationControllerDelegate, UITextFieldDelegate, UITextViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *addContact;

@property (nonatomic, strong) ABPeoplePickerNavigationController *addressBookController;
@property (weak, nonatomic) IBOutlet UITextField *toContactTextView;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet UIButton *setDateButton;
@property (weak, nonatomic) IBOutlet UIButton *scheduleSMSButton;
@property (weak, nonatomic) IBOutlet UIView *bottomLine;
@property (weak, nonatomic) IBOutlet UIView *bottomLineq;
@property (weak, nonatomic) IBOutlet UIView *bottomLines;
@property (weak, nonatomic) IBOutlet UIView *bottomLined;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageTextViewHeight;
@property (nonatomic) CGSize kbSize;

@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@property (weak, nonatomic) IBOutlet UIView *datePickerView;
@property (strong, nonatomic) NSString *selectedDate;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *datePickerBottomConstraint;

@property (weak, nonatomic) IBOutlet UILabel *repeatLabel;
@property (weak, nonatomic) IBOutlet UIButton *repeatSelectionButton;

@property (nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) NSMutableArray *numbers;

@property (weak, nonatomic) IBOutlet UIView *repeatIntervalPickerView;
@property (weak, nonatomic) IBOutlet UIPickerView *repeatIntervalPicker;
@property (weak, nonatomic) IBOutlet UIButton *repeatViewDoneButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *repeatIntervalViewBottomConstraint;

@end

@implementation SMSNewSMSViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    [self.datePicker addTarget: self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
    
    self.addressBookController.peoplePickerDelegate = self;
    self.toContactTextView.delegate = self;
    self.messageTextView.delegate = self;
    
    self.repeatIntervalPicker.delegate = self;
    self.repeatIntervalPicker.dataSource = self;
    
    self.numbers = [NSMutableArray new];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self setUp];
    
    [self addNotifications];
}

- (void)addNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clear:)            name:@"clear"                       object:nil];

}

- (void)keyboardWillShow:(NSNotification *)notification {
    
    NSDictionary *userInfo = [notification userInfo];
    self.kbSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
}

- (void)keyboardWillHide:(NSNotification *)notification {
    
    [UIView animateWithDuration:0.05 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        
        if (self.messageTextView.contentSize.height <= self.view.frame.size.height - (self.messageTextView.frame.origin.y + self.scheduleSMSButton.frame.size.height + 32)) {
            self.messageTextViewHeight.constant = self.messageTextView.contentSize.height;
        }
        
        [self.view layoutIfNeeded];
        
    } completion:nil];
    
}

- (void)clear:(NSNotification *)notification {
    
    self.numbers = [NSMutableArray new];
    [self.toContactTextView resignFirstResponder];
    [self.messageTextView resignFirstResponder];
    [self hideDatePicker];
    [self.datePicker setDate:[NSDate date]];
    self.toContactTextView.text     = NSLocalizedString(@"TypeNumberorAddContactKey", nil);
    self.messageTextView.text       = NSLocalizedString(@"TypeYourMessageKey", nil);
    [self.setDateButton setTitle:NSLocalizedString(@"AddDateKey", nil) forState:UIControlStateNormal];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self hideDatePicker];
    [self hideRepeatIntervalPicker];
    if ([self.toContactTextView.text isEqualToString:NSLocalizedString(@"TypeNumberorAddContactKey", nil)]) {
        self.toContactTextView.text       = @"";
        self.toContactTextView.textColor  = [SMSColors defaultColor];
    } else if (![self.toContactTextView.text isEqualToString:@""]) {
        self.toContactTextView.text       = [NSString stringWithFormat:@"%@, ", self.toContactTextView.text];
        self.toContactTextView.textColor  = [SMSColors defaultColor];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    if ([self.toContactTextView.text containsString:@","]) {
        if ([[[self.toContactTextView.text componentsSeparatedByString:@", "] lastObject] isEqualToString:@""]) {
            self.toContactTextView.text = [self.toContactTextView.text substringToIndex:[self.toContactTextView.text length]-2];
        } else {
            [self.numbers addObject:[[self.toContactTextView.text componentsSeparatedByString:@", "] lastObject]];
        }
    } else if (![self.toContactTextView.text isEqualToString:@""]) {
        [self.numbers addObject:self.toContactTextView.text];
    } else {
        self.toContactTextView.text = NSLocalizedString(@"TypeNumberorAddContactKey", nil);
    }
    
    [self.toContactTextView resignFirstResponder];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    [self hideDatePicker];
    if ([self.messageTextView.text isEqualToString:NSLocalizedString(@"TypeYourMessageKey", nil)]) {
        self.messageTextView.text       = @"";
        self.messageTextView.textColor  = [SMSColors text];
    } else {
        [UIView animateWithDuration:0.05 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            
            if (self.messageTextView.contentSize.height >= self.view.frame.size.height - (self.messageTextView.frame.origin.y + self.kbSize.height)) {
                self.messageTextViewHeight.constant = self.view.frame.size.height - (self.messageTextView.frame.origin.y + self.kbSize.height + 8);
            }
            
            [self.view layoutIfNeeded];
            
        } completion:nil];
    }
    
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    
    if ([self.messageTextView.text isEqualToString:@""]) {
        self.messageTextView.text       = NSLocalizedString(@"TypeYourMessageKey", nil);
        self.messageTextView.textColor  = [UIColor lightGrayColor];
    }
}

-(void)textViewDidChange:(UITextView *)textView {

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [textField resignFirstResponder];
    return NO;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    [self adjustFrames];
    if ([text isEqualToString:@"\n"]) {
        
        if ([self.messageTextView.text isEqualToString:@""]) {
            self.messageTextView.text       = NSLocalizedString(@"TypeYourMessageKey", nil);
            self.messageTextView.textColor  = [UIColor lightGrayColor];
        }
        
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

-(void)adjustFrames
{
    [UIView animateWithDuration:0.05 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        
        if (self.messageTextView.contentSize.height <= self.view.frame.size.height - (self.messageTextView.frame.origin.y + self.kbSize.height)) {
            self.messageTextViewHeight.constant = self.messageTextView.contentSize.height;
        }
        
        [self.view layoutIfNeeded];
        
    } completion:nil];
}

- (IBAction)toggleAddContact:(id)sender {
    
    [self.toContactTextView resignFirstResponder];
    [self.messageTextView resignFirstResponder];
    [self hideDatePicker];
    [self hideRepeatIntervalPicker];
    [self showAddressBook];
}

- (IBAction)toggleScheduleSMSButton:(UIButton *)sender {
    
    if (![self.toContactTextView.text isEqualToString:NSLocalizedString(@"TypeNumberorAddContactKey", nil)] && ![self.messageTextView.text isEqualToString:NSLocalizedString(@"TypeYourMessageKey", nil)] && ![self.messageTextView.text isEqualToString:@""] && [self.datePicker.date timeIntervalSinceNow] > 0 && self.numbers) {
        
        [[SMSManager sharedManager] scheduleSMSWithRecepients:@[self.toContactTextView.text] phones:self.numbers date:self.datePicker.date message:self.messageTextView.text repeatInterval:self.repeatSelectionButton.titleLabel.text];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadSMSs" object:nil userInfo:nil];
        
    } else {
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
        [animation setDuration:0.05];
        [animation setRepeatCount:2];
        [animation setAutoreverses:YES];
        
        if ([self.toContactTextView.text isEqualToString:NSLocalizedString(@"TypeNumberorAddContactKey", nil)] || !self.numbers) {
            
            [animation setFromValue:[NSValue valueWithCGPoint: CGPointMake([self.toContactTextView center].x - 10.0f, [self.toContactTextView center].y)]];
            [animation setToValue:[NSValue valueWithCGPoint: CGPointMake([self.toContactTextView center].x + 10.0f, [self.toContactTextView center].y)]];
            [[self.toContactTextView layer] addAnimation:animation forKey:@"position"];
            
        } else if ([self.datePicker.date timeIntervalSinceNow] < 0 || [self.setDateButton.titleLabel.text isEqualToString:NSLocalizedString(@"AddDateKey", nil)]) {
        
            [animation setFromValue:[NSValue valueWithCGPoint: CGPointMake([self.setDateButton center].x - 10.0f, [self.setDateButton center].y)]];
            [animation setToValue:[NSValue valueWithCGPoint: CGPointMake([self.setDateButton center].x + 10.0f, [self.setDateButton center].y)]];
            [[self.setDateButton layer] addAnimation:animation forKey:@"position"];
            
        } else if ([self.messageTextView.text isEqualToString:NSLocalizedString(@"TypeYourMessageKey", nil)] || [self.messageTextView.text isEqualToString:@""]) {
            
            [animation setFromValue:[NSValue valueWithCGPoint: CGPointMake([self.messageTextView center].x - 10.0f, [self.messageTextView center].y)]];
            [animation setToValue:[NSValue valueWithCGPoint: CGPointMake([self.messageTextView center].x + 10.0f, [self.messageTextView center].y)]];
            [[self.messageTextView layer] addAnimation:animation forKey:@"position"];
        }

    }
}

- (IBAction)toggleSetDateButton:(UIButton *)sender {
    
    [self.toContactTextView resignFirstResponder];
    [self.messageTextView resignFirstResponder];
    [self showDatePicker];
    [self hideRepeatIntervalPicker];
    
    [self.toContactTextView resignFirstResponder];
}

-(void)showAddressBook{
    [self hideDatePicker];
    self.addressBookController = [[ABPeoplePickerNavigationController alloc] init];
    [self.addressBookController setPeoplePickerDelegate:self];
    [self presentViewController:self.addressBookController animated:YES completion:nil];
}

-(void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker{
    [self.addressBookController dismissViewControllerAnimated:YES completion:nil];
}

- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    
    NSString *firstName;
    NSString *lastName;
    NSString *number;
    
    firstName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    lastName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
    if (property == kABPersonPhoneProperty)
    {
        ABMultiValueRef numbers = ABRecordCopyValue(person, property);
        number = (__bridge NSString *) ABMultiValueCopyValueAtIndex(numbers, ABMultiValueGetIndexForIdentifier(numbers, identifier));
    }

    NSString *name = @"";
    if (firstName && lastName) {
        name = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    } else if (!firstName && lastName) {
        name = [NSString stringWithFormat:@"%@", lastName];
    } else if (firstName && !lastName) {
        name = [NSString stringWithFormat:@"%@", firstName];
    }
    
    [self.numbers addObject:number];
    if ([self.toContactTextView.text isEqualToString:NSLocalizedString(@"TypeNumberorAddContactKey", nil)]) {
        self.toContactTextView.text = name;
    } else {
        self.toContactTextView.text = [NSString stringWithFormat:@"%@, %@", self.toContactTextView.text, name];
    }
    
    self.toContactTextView.textColor = [SMSColors defaultColor];
}

- (void)dateChanged:(id)sender
{
    NSDate *pickedDate  = [self.datePicker date];
    self.selectedDate   = [self.dateFormatter stringFromDate:pickedDate];
    [self.setDateButton setTitle:self.selectedDate forState:UIControlStateNormal];
}

- (void)showDatePicker {
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        
        self.datePickerBottomConstraint.constant = 0;
        
        [self.view layoutIfNeeded];
        
    } completion:nil];
}

- (void)hideDatePicker {
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        
        self.datePickerBottomConstraint.constant = -250;
        
        [self.view layoutIfNeeded];
        
    } completion:nil];
}

- (IBAction)toggleDoneButton:(UIButton *)sender {
    
    [self hideDatePicker];
}

- (IBAction)toggleRepeatIntervalViewDoneButton:(UIButton *)sender {
    [self hideRepeatIntervalPicker];
}

- (IBAction)toggleRepeatIntervalSelectionButton:(UIButton *)sender {
    if (self.repeatIntervalViewBottomConstraint.constant == 0) {
        [self hideRepeatIntervalPicker];
    } else {
        [self showRepeatIntervalPicker];
        [self hideDatePicker];
        [self.toContactTextView resignFirstResponder];
        [self.messageTextView resignFirstResponder];
    }
}

- (void)showRepeatIntervalPicker {
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        
        self.repeatIntervalViewBottomConstraint.constant = 0;
        
        [self.view layoutIfNeeded];
        
    } completion:nil];
}

- (void)hideRepeatIntervalPicker {
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        
        self.repeatIntervalViewBottomConstraint.constant = -250;
        
        [self.view layoutIfNeeded];
        
    } completion:nil];
}

#pragma mark - Picker Datasourse

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 5;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 44;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    return self.view.frame.size.width;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (row == 0) {
        return NSLocalizedString(@"NeverRepeatKey", nil);
    } else if (row == 1) {
        return NSLocalizedString(@"DailyRepeatKey", nil);
    } else if (row == 2) {
        return NSLocalizedString(@"WeeklyRepeatKey", nil);
    } else if (row == 3) {
        return NSLocalizedString(@"MonthlyRepeatKey", nil);
    } else {
        return NSLocalizedString(@"YearlyRepeatKey", nil);
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (row == 0) {
        [self.repeatSelectionButton setTitle:NSLocalizedString(@"NeverRepeatKey", nil) forState:UIControlStateNormal];
    } else if (row == 1) {
        [self.repeatSelectionButton setTitle:NSLocalizedString(@"DailyRepeatKey", nil) forState:UIControlStateNormal];
    } else if (row == 2) {
        [self.repeatSelectionButton setTitle:NSLocalizedString(@"WeeklyRepeatKey", nil) forState:UIControlStateNormal];
    } else if (row == 3) {
        [self.repeatSelectionButton setTitle:NSLocalizedString(@"MonthlyRepeatKey", nil) forState:UIControlStateNormal];
    } else {
        [self.repeatSelectionButton setTitle:NSLocalizedString(@"YearlyRepeatKey", nil) forState:UIControlStateNormal];
    }
}

#pragma mark - Helpers 

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.toContactTextView resignFirstResponder];
    [self.messageTextView resignFirstResponder];
    [self hideDatePicker];
    [self hideRepeatIntervalPicker];
}

- (void)setUp {
    
    self.dateFormatter = [NSDateFormatter new];
    [self.dateFormatter setDateFormat:@"MMM dd, yyyy - HH:mm"];
    self.messageTextView.textColor      = [UIColor lightGrayColor];
    self.bottomLine.backgroundColor     = [SMSColors defaultColor];
    self.bottomLineq.backgroundColor    = [SMSColors defaultColor];
    self.bottomLines.backgroundColor    = [SMSColors defaultColor];
    self.doneButton.tintColor           = [SMSColors defaultColor];
    self.repeatLabel.textColor          = [SMSColors text];
    self.bottomLined.backgroundColor    = [SMSColors defaultColor];
    [self.repeatSelectionButton setTintColor:[SMSColors defaultColor]];
    [self.repeatViewDoneButton setTintColor:[SMSColors defaultColor]];
    [self.setDateButton setTintColor:[SMSColors text]];
    [self.scheduleSMSButton setTintColor:[SMSColors defaultColor]];
    [self.repeatSelectionButton setTitle:NSLocalizedString(@"NeverRepeatKey", nil) forState:UIControlStateNormal];
}

@end
