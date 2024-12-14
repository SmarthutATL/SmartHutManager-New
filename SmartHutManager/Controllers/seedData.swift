import CoreData

func seedData(context: NSManagedObjectContext) {
    let fetchRequest: NSFetchRequest<JobCategoryEntity> = JobCategoryEntity.fetchRequest()
    fetchRequest.fetchLimit = 1

    // Check if data already exists to avoid duplicate seeding
    let existingData = try? context.fetch(fetchRequest)
    if existingData?.count ?? 0 > 0 {
        return
    }

    // Data to seed
    let jobData: [String: [(name: String, description: String, price: Double)]] = [
        "Accent Wall": [
            ("Install Shiplap", "Install a shiplap accent wall", 500),
            ("Paint Accent Wall", "Paint an accent wall with up to 3 colors", 250)
        ],
        "Camera Installation": [
            ("Install Outdoor Camera", "Install and configure outdoor security cameras", 150),
            ("Install Indoor Camera", "Install and configure indoor security cameras", 100)
        ],
        "Drywall Repair": [
            ("Patch Small Hole", "Repair a small hole in drywall", 75),
            ("Patch Large Hole", "Repair a large hole in drywall", 150)
        ],
        "Electrical": [
            ("Install Light Fixture", "Install a new light fixture", 200),
            ("Replace Outlet", "Replace existing electrical outlet", 75)
        ],
        "Furniture Assembly": [
            ("Assemble Table", "Assemble a standard-sized table", 100),
            ("Assemble Bookshelf", "Assemble a medium-sized bookshelf", 80)
        ],
        "General Handyman": [
            ("Fix Leaky Faucet", "Fix a leaky faucet", 100),
            ("Install Door Handle", "Replace or install a door handle", 50)
        ],
        "Home Theater Installation": [
            ("Install Surround Sound", "Install a full surround sound system", 300),
            ("Setup Home Theater", "Configure and setup home theater equipment", 400)
        ],
        "Lighting": [
            ("Install Ceiling Fan", "Install and wire a ceiling fan", 150),
            ("Install Dimmer Switch", "Install a dimmer switch", 100)
        ],
        "Painting": [
            ("Paint Room", "Paint a standard-sized room", 500),
            ("Touch Up Painting", "Small touch-up painting", 150)
        ],
        "Picture Hanging": [
            ("Hang Picture Frames", "Hang picture frames (up to 10)", 100),
            ("Install Gallery Wall", "Install a gallery wall", 200)
        ],
        "Plumbing": [
            ("Fix Leaky Pipe", "Repair a leaky pipe", 200),
            ("Unclog Drain", "Unclog a drain", 150)
        ],
        "Pressure Washing": [
            ("Pressure Wash Driveway", "Pressure wash driveway", 250),
            ("Pressure Wash Deck", "Pressure wash deck", 300)
        ],
        "TV Mounting": [
            ("Mount 32-50\" TV", "Mount and secure TV between 32\" and 50\"", 100),
            ("Mount 50-70\" TV", "Mount and secure TV between 50\" and 70\"", 150)
        ]
    ]

    // Seed categories and job options
    for (categoryName, jobOptions) in jobData {
        let category = JobCategoryEntity(context: context)
        category.name = categoryName

        for option in jobOptions {
            let job = JobOptionEntity(context: context)
            job.name = option.name
            job.jobDescription = option.description
            job.price = option.price
            job.category = category // Link to category
        }
    }

    // Save to Core Data
    do {
        try context.save()
        print("Data seeding completed successfully!")
    } catch {
        print("Error seeding data: \(error.localizedDescription)")
    }
}
