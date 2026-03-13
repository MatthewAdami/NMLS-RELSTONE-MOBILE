const courses = [
  {
    _id: 'c_pe_ca_20',
    title: 'California SAFE Pre-Licensing 20-Hour',
    description: 'NMLS-compliant PE package with federal law, ethics, and lending standards.',
    type: 'PE',
    credit_hours: 20,
    price: 199.0,
    has_textbook: true,
    textbook_price: 29.0,
    states_approved: ['CA'],
    modules: [
      { title: 'Federal Law and Regulation', hours: 3 },
      { title: 'Ethics and Consumer Protection', hours: 3 },
      { title: 'Nontraditional Mortgage Products', hours: 2 },
      { title: 'California Mortgage Law', hours: 12 }
    ]
  },
  {
    _id: 'c_pe_tx_20',
    title: 'Texas SAFE Pre-Licensing 20-Hour',
    description: 'Complete PE bundle covering federal and Texas-specific requirements.',
    type: 'PE',
    credit_hours: 20,
    price: 189.0,
    has_textbook: true,
    textbook_price: 25.0,
    states_approved: ['TX'],
    modules: [
      { title: 'Federal Mortgage Guidelines', hours: 3 },
      { title: 'Ethics', hours: 3 },
      { title: 'Nontraditional Products', hours: 2 },
      { title: 'Texas Law and Practice', hours: 12 }
    ]
  },
  {
    _id: 'c_ce_multi_8',
    title: 'Annual CE 8-Hour (Multi-State)',
    description: 'Core CE package accepted in most states for annual renewal.',
    type: 'CE',
    credit_hours: 8,
    price: 79.0,
    has_textbook: false,
    textbook_price: 0,
    states_approved: ['CA', 'TX', 'FL', 'GA', 'NY'],
    modules: [
      { title: 'Federal Law Update', hours: 3 },
      { title: 'Ethics Update', hours: 2 },
      { title: 'Nontraditional Product Update', hours: 2 },
      { title: 'General Elective', hours: 1 }
    ]
  },
  {
    _id: 'c_ce_ca_1',
    title: 'California State CE Elective 1-Hour',
    description: 'California elective CE add-on module.',
    type: 'CE',
    credit_hours: 1,
    price: 25.0,
    has_textbook: false,
    textbook_price: 0,
    states_approved: ['CA'],
    modules: [
      { title: 'California Regulatory Update', hours: 1 }
    ]
  },
  {
    _id: 'c_exam_prep_multi',
    title: 'National Exam Prep Bootcamp',
    description: 'Targeted prep drills, mock tests, and strategy sessions for NMLS exam success.',
    type: 'EXAM_PREP',
    credit_hours: 12,
    price: 149.0,
    has_textbook: false,
    textbook_price: 0,
    states_approved: ['CA', 'TX', 'FL', 'GA', 'NY'],
    modules: [
      { title: 'Exam Pattern Breakdown', hours: 2 },
      { title: 'Question Tactics', hours: 3 },
      { title: 'Timed Mock Sessions', hours: 4 },
      { title: 'Weak-Area Remediation', hours: 3 }
    ]
  }
];

function findCourseById(id) {
  return courses.find((course) => course._id === id) || null;
}

function listCourses({ type, state } = {}) {
  return courses.filter((course) => {
    const matchesType = !type || String(course.type).toUpperCase() === String(type).toUpperCase();
    const matchesState = !state || course.states_approved.includes(String(state).toUpperCase());
    return matchesType && matchesState;
  });
}

function listCoursesForUser({ assignedCourseIds = [], type, state } = {}) {
  const assignedSet = new Set(
    assignedCourseIds
      .map((entry) => String(entry).trim())
      .filter(Boolean)
  );

  const scoped = courses.filter((course) => assignedSet.has(course._id));

  return scoped.filter((course) => {
    const matchesType = !type || String(course.type).toUpperCase() === String(type).toUpperCase();
    const matchesState = !state || course.states_approved.includes(String(state).toUpperCase());
    return matchesType && matchesState;
  });
}

module.exports = {
  courses,
  findCourseById,
  listCourses,
  listCoursesForUser,
};
