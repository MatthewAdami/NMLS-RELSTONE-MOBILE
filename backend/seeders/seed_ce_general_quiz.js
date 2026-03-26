/**
 * Seeder for course quizzes/final exam for:
 * - nmls_course_id: "CE-GENERAL-8HR"
 *
 * Updates only:
 * - modules[].quiz
 * - final_exam.questions / passing_score / time_limit_minutes
 *
 * Run:
 *   node backend/seeders/seed_ce_general_quiz.js
 *
 * Dry run (no DB writes):
 *   DRY_RUN=1 node backend/seeders/seed_ce_general_quiz.js
 */

const path = require('path');
const mongoose = require('mongoose');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const COURSE_NMLS_ID = 'CE-GENERAL-8HR';

const MODULE_QUIZZES = {
  1: [
    {
      number: 1,
      question: 'What is the primary purpose of the Truth in Lending Act (TILA)?',
      options: [
        'Restrict mortgage interest rates automatically',
        'Ensure lenders offer credit to all consumers',
        'Provide clear and standardized disclosures about credit costs',
        'Promote fair lending practices only through marketing'
      ],
      correct_index: 2
    },
    {
      number: 2,
      question: 'What is RESPA primarily focused on?',
      options: [
        'Setting loan origination licensing rules',
        'Regulating settlement services and related fees',
        'Limiting the amount of loan principal you can borrow',
        'Requiring escrow accounts for every property'
      ],
      correct_index: 1
    },
    {
      number: 3,
      question: 'Under TRID, which disclosures are borrowers generally provided during the loan process?',
      options: [
        'Good Faith Estimate and Tolerance Disclosure',
        'Loan Estimate and Closing Disclosure',
        'Disclosure of Rights only at consummation',
        'Only a single settlement statement at closing'
      ],
      correct_index: 1
    },
    {
      number: 4,
      question: 'The Ability-to-Repay (ATR) rule generally requires what?',
      options: [
        'A reasonable, good-faith determination of a consumer’s ability to repay',
        'Approval of all applications regardless of financial capacity',
        'Decisions based only on the property’s collateral value',
        'No verification of income or obligations'
      ],
      correct_index: 0
    }
  ],

  2: [
    {
      number: 1,
      question: 'What ethical duty best describes an MLO’s responsibilities to consumers?',
      options: [
        'Act with integrity and comply with applicable laws while serving the consumer',
        'Prioritize speed of closing even if it conflicts with policy or law',
        'Make decisions based only on personal referral incentives',
        'Provide inaccurate information to “avoid delays”'
      ],
      correct_index: 0
    },
    {
      number: 2,
      question: 'How should conflicts of interest generally be handled?',
      options: [
        'Never disclose conflicts to the consumer',
        'Disclose conflicts and follow legal requirements',
        'Disclose conflicts only after closing',
        'Only disclose conflicts if a complaint is filed'
      ],
      correct_index: 1
    },
    {
      number: 3,
      question: 'During course quizzes/exams, what is required regarding independent completion?',
      options: [
        'It is optional so long as you submit by the deadline',
        'You must complete activities independently without unauthorized aids',
        'Only final exams require independent completion',
        'You may collaborate if your answers are similar'
      ],
      correct_index: 1
    },
    {
      number: 4,
      question: 'Which approach best aligns with handling borrower information responsibly?',
      options: [
        'Share personal data broadly to speed up processing',
        'Protect and use information only as allowed by law and policy',
        'Store sensitive credentials in plaintext for convenience',
        'Remove safeguards after a short trial period'
      ],
      correct_index: 1
    }
  ],

  3: [
    {
      number: 1,
      question: 'Mortgage advertising and communications should generally be:',
      options: [
        'Accurate and not misleading',
        'Broadly promotional even if claims are unverifiable',
        'Made only in print materials and not online',
        'Avoided entirely until after a complaint'
      ],
      correct_index: 0
    },
    {
      number: 2,
      question: 'Which statement best describes the expectation for appraisals?',
      options: [
        'Appraisals should be independent and comply with applicable requirements',
        'Appraisals can be adjusted to match a target value',
        'Appraisals are unnecessary for all refinances',
        'Appraisals may be replaced with informal borrower estimates'
      ],
      correct_index: 0
    },
    {
      number: 3,
      question: 'What recordkeeping principle is generally required?',
      options: [
        'Maintain required records for the period mandated by law/policy',
        'Keep no records after funding',
        'Retain records only for one week',
        'Keep records only when specifically requested'
      ],
      correct_index: 0
    },
    {
      number: 4,
      question: 'Which choice best represents compliant loan origination practices?',
      options: [
        'Follow established procedures and ensure disclosures are correct',
        'Cut corners on required steps to reduce processing time',
        'Disregard consumer information requirements',
        'Rely solely on assumptions without documentation'
      ],
      correct_index: 0
    }
  ],

  4: [
    {
      number: 1,
      question: 'The SAFE Act is designed primarily to require:',
      options: [
        'Registration/licensing for mortgage loan originators (MLOs)',
        'Licensing only for appraisers',
        'Licensing only for underwriters',
        'No registration requirements for MLOs'
      ],
      correct_index: 0
    },
    {
      number: 2,
      question: 'What is the NMLS commonly used for in the context of MLOs?',
      options: [
        'Tracking registration/licensing information and disclosures',
        'Setting underwriting approval rules',
        'Processing loan payments',
        'Guaranteeing interest rate terms'
      ],
      correct_index: 0
    },
    {
      number: 3,
      question: 'Continuing education is intended to help ensure that MLOs:',
      options: [
        'Stay current on changes in laws, regulations, and ethical practices',
        'Avoid all compliance training after licensing',
        'Only complete training during their first year',
        'Skip refresher learning to save time'
      ],
      correct_index: 0
    },
    {
      number: 4,
      question: 'A compliant MLO should generally:',
      options: [
        'Avoid discrimination and follow fair lending requirements',
        'Discriminate based on zip code to optimize outcomes',
        'Ignore consumer rights to reduce workload',
        'Provide conflicting disclosures to different parties'
      ],
      correct_index: 0
    }
  ]
};

const FINAL_EXAM_QUESTIONS = [
  {
    number: 1,
    question: 'Under TRID, the Loan Estimate is generally provided within:',
    options: ['1 business day', '3 business days', '10 business days', 'At consummation'],
    correct_index: 1
  },
  {
    number: 2,
    question: 'RESPA prohibits certain practices sometimes referred to as:',
    options: ['Interest rate caps', 'Kickbacks and referral fees', 'Late payment penalties', 'Escrow account requirements'],
    correct_index: 1
  },
  {
    number: 3,
    question: 'An MLO should not:',
    options: ['Misrepresent material facts', 'Maintain accurate disclosures', 'Follow applicable policies', 'Verify required information'],
    correct_index: 0
  },
  {
    number: 4,
    question: 'Borrower information should generally be accessed and shared only:',
    options: ['By unauthorized parties to accelerate processing', 'As allowed by law, and on a need-to-know basis', 'Only after a loan is closed', 'Only if a complaint is filed'],
    correct_index: 1
  },
  {
    number: 5,
    question: 'Ability-to-Repay generally requires a creditor to make a:',
    options: [
      'Reasonable, good-faith determination based on verified information',
      'Guarantee of repayment regardless of circumstances',
      'Decision based only on property value',
      'Determination without regard to income or obligations'
    ],
    correct_index: 0
  },
  {
    number: 6,
    question: 'Mortgage loan origination practices should include:',
    options: [
      'Accurate disclosures and adherence to compliance procedures',
      'Omitting required disclosures when inconvenient',
      'Disregarding documentation requirements',
      'Providing different terms to different parties without basis'
    ],
    correct_index: 0
  },
  {
    number: 7,
    question: 'During NMLS compliance training quizzes/exams, you must:',
    options: [
      'Use unauthorized aids to complete answers quickly',
      'Complete activities independently',
      'Share questions with other students',
      'Copy answers to speed up submission'
    ],
    correct_index: 1
  },
  {
    number: 8,
    question: 'Continuing education generally helps ensure that professionals can:',
    options: [
      'Stay current with legal and regulatory changes',
      'Avoid learning new requirements',
      'Remove compliance obligations',
      'Only rely on outdated guidance'
    ],
    correct_index: 0
  },
  {
    number: 9,
    question: 'Advertising and communications should be:',
    options: ['Misleading if it increases leads', 'Accurate and not deceptive', 'Only promotional without substantiation', 'Unavailable to consumers'],
    correct_index: 1
  },
  {
    number: 10,
    question: 'A fundamental goal of mortgage compliance is to:',
    options: [
      'Reduce compliance to minimum standards only',
      'Protect consumers and ensure lawful origination practices',
      'Eliminate verification of key information',
      'Bypass disclosures when possible'
    ],
    correct_index: 1
  }
];

function getOrderNumber(moduleLike) {
  const raw = moduleLike?.order ?? moduleLike?.module_order ?? moduleLike?.idx;
  if (typeof raw === 'number') return raw;
  const n = parseInt(String(raw), 10);
  return Number.isNaN(n) ? null : n;
}

async function main() {
  if (!process.env.MONGO_URI) {
    console.error('Missing MONGO_URI. Put it in backend/.env before running.');
    process.exit(1);
  }

  const dryRun = String(process.env.DRY_RUN || '').trim() === '1';

  await mongoose.connect(process.env.MONGO_URI);
  const db = mongoose.connection.db;
  const courses = db.collection('courses');

  const course = await courses.findOne({ nmls_course_id: COURSE_NMLS_ID });
  if (!course) {
    console.error(`Course not found: nmls_course_id=${COURSE_NMLS_ID}`);
    await mongoose.disconnect();
    process.exit(1);
  }

  const courseModules = Array.isArray(course.modules) ? course.modules : [];

  // Seed module quizzes by module order.
  const updatedModules = courseModules.map((m) => {
    const order = getOrderNumber(m);
    if (order != null && MODULE_QUIZZES[order]) {
      return {
        ...m,
        quiz: MODULE_QUIZZES[order]
      };
    }
    return m;
  });

  const updatedFinalExam = {
    ...(course.final_exam || {}),
    questions: FINAL_EXAM_QUESTIONS,
    passing_score: (course.final_exam && course.final_exam.passing_score) ?? 70,
    time_limit_minutes:
      (course.final_exam && course.final_exam.time_limit_minutes) ?? 90,
    title:
      (course.final_exam && course.final_exam.title) ?? 'Final Exam'
  };

  if (dryRun) {
    const counts = updatedModules
      .map((m) => ({
        order: getOrderNumber(m),
        quizCount: Array.isArray(m.quiz) ? m.quiz.length : 0
      }))
      .filter((x) => x.order != null);

    console.log('[DRY_RUN] Found course:', COURSE_NMLS_ID);
    console.log('[DRY_RUN] Module quiz counts:', counts);
    console.log('[DRY_RUN] Final exam question count:', FINAL_EXAM_QUESTIONS.length);
    await mongoose.disconnect();
    return;
  }

  const result = await courses.updateOne(
    { _id: course._id },
    {
      $set: {
        modules: updatedModules,
        final_exam: updatedFinalExam,
        // Optional compatibility for other code paths.
        finalExam: updatedFinalExam
      }
    }
  );

  console.log('Seed complete for:', COURSE_NMLS_ID);
  console.log('Matched:', result.matchedCount, 'Modified:', result.modifiedCount);

  await mongoose.disconnect();
}

main().catch(async (err) => {
  console.error('Seeding failed:', err?.message || err);
  try {
    await mongoose.disconnect();
  } catch (_) {
    // ignore
  }
  process.exit(1);
});

