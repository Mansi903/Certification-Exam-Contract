// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CertificationExam {

    // Structure for an exam
    struct Exam {
        string title;               // The title of the exam
        string description;         // A brief description of the exam
        uint256 passingScore;       // The passing score for the exam
        address organizer;          // The address of the exam organizer
        uint256 startTime;          // Timestamp when the exam started
        uint256 endTime;            // Timestamp when the exam ends
        bool isCompleted;           // To indicate if the exam is completed
    }

    // Structure for a student's exam record
    struct StudentRecord {
        uint256 score;              // The score of the student
        bool passed;                // Whether the student passed the exam
        bool certificateIssued;     // Whether the certificate has been issued
    }

    // Mapping of exam ID to the Exam structure
    mapping(uint256 => Exam) public exams;

    // Mapping of (exam ID => student address => StudentRecord)
    mapping(uint256 => mapping(address => StudentRecord)) public studentRecords;

    uint256 public examCount;  // Counter for the number of exams created
    address public admin;      // Admin address for creating and managing exams

    // Events
    event ExamCreated(uint256 indexed examId, string title, address organizer);
    event ExamCompleted(uint256 indexed examId, address student, uint256 score, bool passed);
    event CertificateIssued(uint256 indexed examId, address student);

    // Modifier to restrict actions to only the exam organizer
    modifier onlyOrganizer(uint256 _examId) {
        require(msg.sender == exams[_examId].organizer, "Only the exam organizer can perform this action");
        _;
    }

    // Modifier to check if the exam is completed
    modifier onlyAfterExam(uint256 _examId) {
        require(exams[_examId].isCompleted, "The exam has not been completed yet");
        _;
    }

    // Modifier to ensure the caller is the admin
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can perform this action");
        _;
    }

    constructor() {
        admin = msg.sender;  // Set the contract creator as the admin
    }

    // Function to create a new exam
    function createExam(
        string memory _title,
        string memory _description,
        uint256 _passingScore,
        uint256 _startTime,
        uint256 _endTime
    ) public onlyAdmin returns (uint256) {
        examCount++;
        exams[examCount] = Exam({
            title: _title,
            description: _description,
            passingScore: _passingScore,
            organizer: msg.sender,
            startTime: _startTime,
            endTime: _endTime,
            isCompleted: false
        });

        emit ExamCreated(examCount, _title, msg.sender);
        return examCount;
    }

    // Function for a student to take an exam (submit answers)
    function takeExam(uint256 _examId, uint256 _score) public {
        require(block.timestamp >= exams[_examId].startTime, "The exam has not started yet");
        require(block.timestamp <= exams[_examId].endTime, "The exam has already ended");
        require(!exams[_examId].isCompleted, "The exam has already been completed");

        // Record the student's score
        studentRecords[_examId][msg.sender].score = _score;

        // Determine if the student passed or failed
        studentRecords[_examId][msg.sender].passed = _score >= exams[_examId].passingScore;

        emit ExamCompleted(_examId, msg.sender, _score, studentRecords[_examId][msg.sender].passed);
    }

    // Function for the organizer to mark the exam as completed
    function completeExam(uint256 _examId) public onlyOrganizer(_examId) {
        exams[_examId].isCompleted = true;
    }

    // Function to issue a certificate to a passing student
    function issueCertificate(uint256 _examId, address _student) public onlyOrganizer(_examId) onlyAfterExam(_examId) {
        require(studentRecords[_examId][_student].passed, "The student did not pass the exam");
        require(!studentRecords[_examId][_student].certificateIssued, "Certificate has already been issued");

        // Mark the certificate as issued
        studentRecords[_examId][_student].certificateIssued = true;

        emit CertificateIssued(_examId, _student);
    }

    // Function to verify a student's certificate
    function verifyCertificate(uint256 _examId, address _student) public view returns (bool passed, bool certificateIssued) {
        StudentRecord memory record = studentRecords[_examId][_student];
        return (record.passed, record.certificateIssued);
    }

    // Function to get the details of an exam
    function getExamDetails(uint256 _examId) public view returns (
        string memory title,
        string memory description,
        uint256 passingScore,
        address organizer,
        uint256 startTime,
        uint256 endTime,
        bool isCompleted
    ) {
        Exam memory exam = exams[_examId];
        return (
            exam.title,
            exam.description,
            exam.passingScore,
            exam.organizer,
            exam.startTime,
            exam.endTime,
            exam.isCompleted
        );
    }

    // Function to get the exam result for a student
    function getExamResult(uint256 _examId, address _student) public view returns (uint256 score, bool passed) {
        StudentRecord memory record = studentRecords[_examId][_student];
        return (record.score, record.passed);
    }
}
