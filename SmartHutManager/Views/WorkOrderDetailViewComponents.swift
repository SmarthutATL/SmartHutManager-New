import SwiftUI

extension WorkOrderDetailView {

    // MARK: - Customer Information Section
    var customerInformationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Centered Customer Name
            HStack {
                Spacer()
                Text(workOrder.customer?.name ?? "Unknown Customer")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
            }

            // Centered Tappable Address with Icon
            if let address = workOrder.customer?.address, !address.isEmpty {
                HStack {
                    Spacer()
                    Image(systemName: "map.fill")
                        .foregroundColor(.blue)
                    Button(action: {
                        openMaps(for: address)
                    }) {
                        Text(address)
                            .font(.title3)
                            .foregroundColor(.blue)
                            .underline()
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                }
            } else {
                HStack {
                    Spacer()
                    Image(systemName: "map.fill")
                        .foregroundColor(.gray)
                    Text("No Address")
                        .font(.title3)
                        .foregroundColor(.gray)
                    Spacer()
                }
            }

            // Tappable Phone Number with Action Sheet for Call and Text
            if let phoneNumber = workOrder.customer?.phoneNumber, !phoneNumber.isEmpty {
                HStack {
                    Spacer()
                    Image(systemName: "phone.fill")
                        .foregroundColor(.green)
                    
                    Button(action: {
                        isShowingActionSheet = true // Show action sheet on tap
                    }) {
                        Text(phoneNumber)
                            .font(.title3)
                            .foregroundColor(.green)
                            .underline()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .actionSheet(isPresented: $isShowingActionSheet) {
                        ActionSheet(
                            title: Text("Contact Options"),
                            message: Text("Choose an option for \(phoneNumber)"),
                            buttons: [
                                .default(Text("Text")) {
                                    showingMessageCompose = true
                                },
                                .default(Text("Call")) {
                                    callPhoneNumber(phoneNumber)
                                },
                                .cancel()
                            ]
                        )
                    }
                    Spacer()
                }
            } else {
                HStack {
                    Spacer()
                    Image(systemName: "phone.fill")
                        .foregroundColor(.gray)
                    Text("No Phone Number")
                        .font(.title3)
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(BlurView(style: .systemUltraThinMaterialDark))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
        .shadow(radius: 10)
    }

    // Function to open maps with the given address
    func openMaps(for address: String) {
        let formattedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = URL(string: "http://maps.apple.com/?q=\(formattedAddress)")!
        UIApplication.shared.open(url)
    }

    // Function to call a given phone number
    func callPhoneNumber(_ phoneNumber: String) {
        let formattedNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        if let url = URL(string: "tel://\(formattedNumber)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    // Custom BlurView for a modern background
    struct BlurView: UIViewRepresentable {
        var style: UIBlurEffect.Style

        func makeUIView(context: Context) -> UIVisualEffectView {
            let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
            return view
        }

        func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
    }
    // MARK: - Callback Information Section
    var callbackInformationSection: some View {
        VStack(spacing: 8) {
            // Center the header text and make it smaller for compactness
            Text("Callback?")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack {
                Spacer() // Center the toggle
                Toggle(isOn: Binding(
                    get: { workOrder.isCallback },
                    set: { _ in } // No-op since this toggle is non-interactive
                )) {
                    Text("") // Empty label
                }
                .toggleStyle(WideToggleStyle(isOn: workOrder.isCallback)) // Custom toggle style
                .frame(width: 80, height: 35) // Adjust toggle size
                .disabled(true) // Disable user interaction
                Spacer()
            }
        }
        .padding(8)
        .background(Color.clear) // Transparent background
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1) // Subtle border
        )
        .cornerRadius(8)
        .frame(maxWidth: .infinity, alignment: .center) // Center everything
    }

    // MARK: - Custom Wide Toggle Style (No Text)
    struct WideToggleStyle: ToggleStyle {
        var isOn: Bool
        
        func makeBody(configuration: Configuration) -> some View {
            ZStack {
                // Background of the toggle
                RoundedRectangle(cornerRadius: 15)
                    .fill(configuration.isOn ? Color.green : Color.red) // Green for on, red for off
                    .frame(width: 60, height: 30) // Toggle size
                
                // Circle inside the toggle
                Circle()
                    .fill(Color.white)
                    .frame(width: 26, height: 26) // Circle size
                    .offset(x: configuration.isOn ? 15 : -15) // Position of the circle
            }
            .onTapGesture {
                withAnimation(.spring()) {
                    configuration.isOn.toggle()
                }
            }
        }
    }
    
    // MARK: - Work Order Details Section
    var workOrderDetails: some View {
        VStack(alignment: .center, spacing: 8) {
            // Centered Category Text
            Text(workOrder.category ?? "No Category")
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)

            // White Description Text
            Text(workOrder.workOrderDescription ?? "No Description")
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    // MARK: - Status Update Section
    var statusUpdateSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Update Work Order Status")
                .font(.headline)

            HStack(spacing: 15) {
                statusButton("Open", color: .red, isSelected: selectedStatus == "Open") // Open is now red
                statusButton("Completed", color: .green, isSelected: selectedStatus == "Completed") // Completed remains green
                statusButton("Incomplete", color: .yellow, isSelected: selectedStatus == "Incomplete") // Incomplete is now yellow
            }
        }
    }

    func statusButton(_ title: String, color: Color, isSelected: Bool) -> some View {
        Button(action: {
            selectedStatus = title
        }) {
            Text(title)
                .font(.headline)
                .foregroundColor(isSelected ? .white : color)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isSelected ? color : Color.clear)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color, lineWidth: 2)
                )
        }
    }
    // MARK: - Tasks Section
    var tasksSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Tasks")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(tasks) { task in
                        Button(action: {
                            // Toggle task completion status
                            task.isComplete.toggle()
                            saveContext() // Save the context when the task status is updated
                        }) {
                            VStack(spacing: 10) {
                                // Task name and description centered
                                Text(task.name ?? "No Task Name")
                                    .font(.headline)
                                    .foregroundColor(.white) // White text for both states
                                    .multilineTextAlignment(.center)
                                
                                Text(task.taskDescription ?? "No Task Description")
                                    .font(.subheadline)
                                    .foregroundColor(.white) // White text for both states
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .frame(width: 200, height: 180)
                            .background(task.isComplete ? Color.green : Color.red) // Green if complete, red if not
                            .cornerRadius(10)
                            .shadow(radius: 5)
                        }
                        .buttonStyle(PlainButtonStyle()) // Remove button styling
                    }
                    
                    // Add Task Button
                    Button(action: {
                        isAddingTask = true
                    }) {
                        VStack {
                            Image(systemName: "plus.circle")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.blue)
                            Text("Add Task")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .frame(width: 200, height: 180)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                }
                .padding(.horizontal)
            }
            
            // Add Task Form
            if isAddingTask {
                VStack(spacing: 10) {
                    TextField("Task Name", text: $newTaskName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Task Description", text: $newTaskDescription)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    HStack {
                        Button(action: addTask) {
                            Text("Save Task")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                        Button(action: { isAddingTask = false }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Summary Section
    var summarySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Summary of Work")
                .font(.headline)
            
            ZStack(alignment: .topLeading) {
                if summary.isEmpty {
                    Text("Enter summary of the work done")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                }
                
                // Use CustomTextView for the summary input
                CustomTextView(text: $summary)
                    .padding(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .frame(height: 150)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Photos Folder Section
    var photosFolderSection: some View {
        VStack(spacing: 5) {
            Button(action: {
                isShowingPhotosView = true
            }) {
                VStack {
                    Image(systemName: "folder.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                    Text("Work Order Pictures")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 16)
    }

    // MARK: - Action Buttons
    var actionButtons: some View {
        HStack(spacing: 15) {
            Button(action: {
                isShowingPhotoPicker = true
            }) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text("Upload Photos")
                }
                .padding()
                .frame(width: 160)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            Button(action: submitWorkOrder) {
                HStack {
                    Image(systemName: "checkmark.circle")
                    Text("Submit Work Order")
                }
                .padding()
                .frame(width: 160)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding(.top)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
