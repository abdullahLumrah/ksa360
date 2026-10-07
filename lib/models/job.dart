class JobFilter {
  const JobFilter({required this.name, required this.count});

  final String name;
  final int count;

  factory JobFilter.fromJson(Map<String, dynamic> json) {
    return JobFilter(
      name: (json['name'] ?? '').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class Job {
  const Job({
    required this.id,
    required this.title,
    required this.category,
    required this.companyName,
    required this.companyIndustry,
    required this.city,
    required this.locationText,
    required this.workMode,
    required this.employmentType,
    required this.experienceRequired,
    required this.educationRequired,
    required this.salaryDisplay,
    required this.salaryPosted,
    required this.summary,
    required this.description,
    required this.applyUrl,
    required this.listingUrl,
    required this.datePosted,
    required this.deadline,
    required this.source,
    required this.status,
  });

  final String id;
  final String title;
  final String category;
  final String companyName;
  final String companyIndustry;
  final String city;
  final String locationText;
  final String workMode;
  final String employmentType;
  final String experienceRequired;
  final String educationRequired;
  final String salaryDisplay;
  final bool salaryPosted;
  final String summary;
  final String description;
  final String applyUrl;
  final String listingUrl;
  final String datePosted;
  final String deadline;
  final String source;
  final String status;

  String get place => locationText.isNotEmpty ? locationText : city;
  String get applyLink => applyUrl.isNotEmpty ? applyUrl : listingUrl;

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      companyName: (json['companyName'] ?? '').toString(),
      companyIndustry: (json['companyIndustry'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      locationText: (json['locationText'] ?? json['city'] ?? '').toString(),
      workMode: (json['workMode'] ?? '').toString(),
      employmentType: (json['employmentType'] ?? '').toString(),
      experienceRequired: (json['experienceRequired'] ?? '').toString(),
      educationRequired: (json['educationRequired'] ?? '').toString(),
      salaryDisplay: (json['salaryDisplay'] ?? '').toString(),
      salaryPosted: json['salaryPosted'] == true,
      summary: (json['summary'] ?? '').toString(),
      description: (json['description'] ?? json['summary'] ?? '').toString(),
      applyUrl: (json['applyUrl'] ?? '').toString(),
      listingUrl: (json['listingUrl'] ?? '').toString(),
      datePosted: (json['datePosted'] ?? '').toString(),
      deadline: (json['deadline'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}
