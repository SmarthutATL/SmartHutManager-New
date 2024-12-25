import SwiftUI

struct ManageJobCategoriesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: JobCategoryEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \JobCategoryEntity.name, ascending: true)]
    )
    var categories: FetchedResults<JobCategoryEntity>

    @State private var isAddingCategory = false
    @State private var isAddingJob = false
    @State private var selectedCategory: JobCategoryEntity?

    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(categories, id: \.self) { category in
                        DisclosureGroup {
                            ForEach((category.jobs?.allObjects as? [JobOptionEntity]) ?? [], id: \.self) { job in
                                JobRow(job: job)
                            }
                            Button(action: {
                                selectedCategory = category
                                isAddingJob = true
                            }) {
                                Label("Add Job", systemImage: "plus.circle")
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                        } label: {
                            Text(category.name ?? "Unknown Category")
                                .font(.headline)
                        }
                    }
                    .onDelete(perform: deleteCategory)
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Manage Categories")

                // Floating Add Category Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { isAddingCategory = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .sheet(isPresented: $isAddingCategory) {
                AddCategoryView { name in
                    addCategory(name: name)
                }
            }
            .sheet(isPresented: $isAddingJob) {
                AddJobView(category: selectedCategory ?? JobCategoryEntity(context: viewContext)) { name, description, price in
                    if let category = selectedCategory {
                        addJob(to: category, name: name, description: description, price: price)
                    }
                }
            }
            .onChange(of: isAddingJob) { newValue, _ in
                if newValue && selectedCategory == nil {
                    isAddingJob = false
                }
            }
        }
    }

    private func addCategory(name: String) {
        guard !name.isEmpty else { return }
        let newCategory = JobCategoryEntity(context: viewContext)
        newCategory.name = name

        do {
            try viewContext.save()
        } catch {
            print("Error saving new category: \(error.localizedDescription)")
        }
    }

    private func addJob(to category: JobCategoryEntity, name: String, description: String, price: Double) {
        let newJob = JobOptionEntity(context: viewContext)
        newJob.name = name
        newJob.jobDescription = description
        newJob.price = price
        newJob.category = category

        do {
            try viewContext.save()
        } catch {
            print("Error adding new job: \(error.localizedDescription)")
        }
    }

    private func deleteCategory(at offsets: IndexSet) {
        for index in offsets {
            let category = categories[index]
            viewContext.delete(category)
        }

        do {
            try viewContext.save()
        } catch {
            print("Error deleting category: \(error.localizedDescription)")
        }
    }
}

struct JobRow: View {
    var job: JobOptionEntity

    var body: some View {
        VStack(alignment: .leading) {
            Text(job.name ?? "Unknown Job").font(.headline)
            Text(job.jobDescription ?? "").font(.subheadline).foregroundColor(.gray)
            Text(String(format: "$%.2f", job.price)).font(.subheadline).foregroundColor(.blue)
        }
        .padding(.vertical, 5)
    }
}

struct AddCategoryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""

    var onAdd: (String) -> Void

    var body: some View {
        NavigationView {
            Form {
                TextField("Category Name", text: $name)
            }
            .navigationTitle("Add Category")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onAdd(name)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct AddJobView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var priceText = ""

    var category: JobCategoryEntity
    var onAdd: (String, String, Double) -> Void

    var body: some View {
        NavigationView {
            Form {
                TextField("Job Name", text: $name)
                TextField("Description", text: $description)
                TextField("Price", text: $priceText)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Add Job")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let price = Double(priceText) {
                            onAdd(name, description, price)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || description.isEmpty || Double(priceText) == nil)
                }
            }
        }
    }
}
