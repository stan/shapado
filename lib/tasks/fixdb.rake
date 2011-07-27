desc "Fix all"
task :fixall => [:environment, "fixdb:anonymous"] do
end

namespace :fixdb do
  task :anonymous => [:environment] do
    Question.set({:anonymous => nil}, {:anonymous => false})
    Answer.set({:anonymous => nil}, {:anonymous => false})
  end

  task :clean_memberships => [:environment] do
    User.find_each do |u|
      count = 0
      new_memberhip_list = u.membership_list
      u.membership_list.each do |group_id, vals|
        if vals["last_activity_at"].nil? || vals["reputation"] == 0.0
          new_memberhip_list.delete(group_id)
          count += 1
        end
      end
      u.set(:membership_list => new_memberhip_list)
      if count > 0
        p "#{u.login}: #{count}"
      end
    end
  end

  task :answered => [:environment] do
    accepted_count = 0
    answered_count = 0

    Question.find_each do |question|
      next if question.answered || question.answers_count == 0

      if question.answer.present?
        question.set(:accepted => true, :answered => true, :answered_with_id => question.answer_id)
        accepted_count += 1
      else
        ok = false

        answered_with = nil
        question.answers.all(:order => "votes_average desc").each do |answer|
          if answer.votes_average > 0
            ok = true
            answered_with = answer
            break
          end
        end

        if ok && answered_with
          question.set(:answered => true, :answered_with_id => answered_with.id)
          answered_count += 1
        end
      end
    end

    puts "#{accepted_count} answers were marked as accepted(and answered).\n#{answered_count} answers were marked as answered"
  end
end

