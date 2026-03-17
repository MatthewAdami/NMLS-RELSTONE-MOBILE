const { listCourses } = require('./courses');

const STATES = [
  ['AL', 'Alabama'],
  ['AK', 'Alaska'],
  ['AZ', 'Arizona'],
  ['AR', 'Arkansas'],
  ['CA', 'California'],
  ['CO', 'Colorado'],
  ['CT', 'Connecticut'],
  ['DE', 'Delaware'],
  ['DC', 'District of Columbia'],
  ['FL', 'Florida'],
  ['GA', 'Georgia'],
  ['HI', 'Hawaii'],
  ['ID', 'Idaho'],
  ['IL', 'Illinois'],
  ['IN', 'Indiana'],
  ['IA', 'Iowa'],
  ['KS', 'Kansas'],
  ['KY', 'Kentucky'],
  ['LA', 'Louisiana'],
  ['ME', 'Maine'],
  ['MD', 'Maryland'],
  ['MA', 'Massachusetts'],
  ['MI', 'Michigan'],
  ['MN', 'Minnesota'],
  ['MS', 'Mississippi'],
  ['MO', 'Missouri'],
  ['MT', 'Montana'],
  ['NE', 'Nebraska'],
  ['NV', 'Nevada'],
  ['NH', 'New Hampshire'],
  ['NJ', 'New Jersey'],
  ['NM', 'New Mexico'],
  ['NY', 'New York'],
  ['NC', 'North Carolina'],
  ['ND', 'North Dakota'],
  ['OH', 'Ohio'],
  ['OK', 'Oklahoma'],
  ['OR', 'Oregon'],
  ['PA', 'Pennsylvania'],
  ['RI', 'Rhode Island'],
  ['SC', 'South Carolina'],
  ['SD', 'South Dakota'],
  ['TN', 'Tennessee'],
  ['TX', 'Texas'],
  ['UT', 'Utah'],
  ['VT', 'Vermont'],
  ['VA', 'Virginia'],
  ['WA', 'Washington'],
  ['WV', 'West Virginia'],
  ['WI', 'Wisconsin'],
  ['WY', 'Wyoming'],
];

const DEFAULT_SUBJECT_BREAKDOWN = [
  { subject: 'Federal Law and Regulations', hours: 3 },
  { subject: 'Ethics and Consumer Protection', hours: 3 },
  { subject: 'Nontraditional Mortgage Products', hours: 2 },
  { subject: 'State-Specific Mortgage Law', hours: 12 },
];

const DEFAULT_REQUIREMENT = {
  preLicensing: {
    totalHours: 20,
    subjectBreakdown: DEFAULT_SUBJECT_BREAKDOWN,
  },
  exam: {
    format: 'National + state component (computer-based)',
    passScore: '75%',
    scheduling: 'Schedule through NMLS-approved test providers after PE completion.',
  },
  postExamSteps: [
    'Complete fingerprinting and criminal background check through NMLS.',
    'Submit MU4 application and required disclosures.',
    'Authorize credit report and pay filing fees.',
    'Complete employer sponsorship in NMLS before originating loans.',
  ],
  ceRenewal: {
    hours: 8,
    frequency: 'Annually',
    details: 'Complete CE by the annual NMLS renewal window and avoid repeated-year credit.',
  },
};

const OVERRIDES = {
  CA: {
    exam: {
      format: 'National test + California DRE requirements review',
      passScore: '75%',
      scheduling: 'Book exam in NMLS after PE; monitor CA DRE updates for state rules.',
    },
    postExamSteps: [
      'Pass SAFE national test and keep score active.',
      'Submit California MLO application through NMLS.',
      'Complete background check and credit authorization.',
      'Associate sponsorship with a California-licensed employer.',
    ],
    ceRenewal: {
      hours: 8,
      frequency: 'Annually',
      details: 'Includes federal + ethics + nontraditional + CA elective requirements.',
    },
  },
  TX: {
    preLicensing: {
      totalHours: 23,
      subjectBreakdown: [
        { subject: 'Federal Law and Regulations', hours: 3 },
        { subject: 'Ethics and Consumer Protection', hours: 3 },
        { subject: 'Nontraditional Mortgage Products', hours: 2 },
        { subject: 'Texas-Specific Mortgage Law', hours: 3 },
        { subject: 'Additional Elective/Practice Training', hours: 12 },
      ],
    },
    exam: {
      format: 'National + UST component (computer-based)',
      passScore: '75%',
      scheduling: 'Schedule exam through NMLS once PE and account setup are complete.',
    },
  },
  FL: {
    exam: {
      format: 'National + UST component',
      passScore: '75%',
      scheduling: 'Book in NMLS and complete all pre-licensing prior to selecting date.',
    },
    ceRenewal: {
      hours: 8,
      frequency: 'Annually',
      details: 'Complete annual CE and maintain active sponsorship for renewal.',
    },
  },
  NY: {
    preLicensing: {
      totalHours: 20,
      subjectBreakdown: [
        { subject: 'Federal Law and Regulations', hours: 3 },
        { subject: 'Ethics and Consumer Protection', hours: 3 },
        { subject: 'Nontraditional Mortgage Products', hours: 2 },
        { subject: 'New York Law and Practice', hours: 12 },
      ],
    },
    exam: {
      format: 'National + UST component',
      passScore: '75%',
      scheduling: 'Schedule through NMLS and verify any additional NY DFS checklist items.',
    },
  },
};

function mergeRequirement(override = {}) {
  return {
    preLicensing: {
      ...DEFAULT_REQUIREMENT.preLicensing,
      ...override.preLicensing,
      subjectBreakdown:
        override.preLicensing?.subjectBreakdown ||
        DEFAULT_REQUIREMENT.preLicensing.subjectBreakdown,
    },
    exam: {
      ...DEFAULT_REQUIREMENT.exam,
      ...override.exam,
    },
    postExamSteps: override.postExamSteps || DEFAULT_REQUIREMENT.postExamSteps,
    ceRenewal: {
      ...DEFAULT_REQUIREMENT.ceRenewal,
      ...override.ceRenewal,
    },
  };
}

function mapCourseForCta(course) {
  return {
    id: course._id,
    title: course.title,
    type: course.type,
    creditHours: course.credit_hours,
    price: course.price,
    textbookPrice: course.textbook_price,
    enrollCta: {
      label: 'Enroll',
      action: 'navigate-login',
      route: '/login',
      payload: { courseId: course._id },
    },
  };
}

function listStateSummaries({ search } = {}) {
  const needle = String(search || '').trim().toLowerCase();

  return STATES.map(([code, name]) => {
    const req = mergeRequirement(OVERRIDES[code]);
    const courses = listCourses({ state: code }).map(mapCourseForCta);

    return {
      stateCode: code,
      stateName: name,
      preLicensingHours: req.preLicensing.totalHours,
      ceHours: req.ceRenewal.hours,
      examPassScore: req.exam.passScore,
      relstoneCourseCount: courses.length,
    };
  }).filter((entry) => {
    if (!needle) return true;
    return (
      entry.stateCode.toLowerCase().includes(needle) ||
      entry.stateName.toLowerCase().includes(needle)
    );
  });
}

function getStateRequirement(stateCode) {
  const normalized = String(stateCode || '').trim().toUpperCase();
  const found = STATES.find(([code]) => code === normalized);
  if (!found) return null;

  const [code, name] = found;
  const req = mergeRequirement(OVERRIDES[code]);
  const courses = listCourses({ state: code }).map(mapCourseForCta);

  return {
    stateCode: code,
    stateName: name,
    ...req,
    relstoneCourses: courses,
  };
}

module.exports = {
  listStateSummaries,
  getStateRequirement,
};
