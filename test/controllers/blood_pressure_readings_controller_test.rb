require "test_helper"

class BloodPressureReadingsControllerTest < ActionDispatch::IntegrationTest
  include RoutingHelper

  setup do
    @user = users(:one)
    sign_in_as(@user)
    @bp_reading = @user.blood_pressure_readings.first
  end

  describe "authentication" do
    before { sign_out }

    it "redirects unauthenticated users away from create action" do
      assert_no_difference("BloodPressureReading.count") do
        post blood_pressure_readings_path, params: { systolic: 120, diastolic: 80, date: Date.current }
      end
      assert_redirected_to new_session_path
    end

    it "redirects unauthenticated users away from the edit action" do
      get edit_blood_pressure_reading_path @bp_reading
      assert_redirected_to new_session_path
    end

    it "redirects unauthorized users away from the destroy action" do
      assert_no_difference("BloodPressureReading.count") do
        delete blood_pressure_reading_path @bp_reading
      end
      assert_redirected_to new_session_path
    end
  end

  describe "#create" do
    context "with valid params" do
      it "creates a new blood pressure reading" do
        @user.blood_pressure_readings.destroy_all
        date = Date.current
        assert_difference("BloodPressureReading.count", 1) do
          post blood_pressure_readings_path, params: { blood_pressure_reading: { systolic: 121, diastolic: 80, date: date } }
        end
        assert_not_empty @user.reload.blood_pressure_readings
      end

      it "redirects to the day page after creation" do
        @user.blood_pressure_readings.destroy_all
        date = Date.current
        post blood_pressure_readings_path, params: { blood_pressure_reading: { systolic: 121, diastolic: 80, date: date } }
        new_bp_reading = BloodPressureReading.order(:created_at).last
        assert_redirected_to day_path_for(new_bp_reading)
      end

      it "scopes the blood pressure reading to the logged-in user" do
        @user.blood_pressure_readings.destroy_all
        date = Date.current
        post blood_pressure_readings_path, params: { blood_pressure_reading: { systolic: 121, diastolic: 80, date: date } }
        new_bp_reading = BloodPressureReading.order(:created_at).last
        assert_equal @user.id, new_bp_reading.user_id
      end
    end

    context "with invalid params" do
      it "does not create a blood pressure reading" do
        assert_no_difference("BloodPressureReading.count") do
          post blood_pressure_readings_path, params: { blood_pressure_reading: { systolic: nil, diastolic: 80, date: Date.current } }
        end
      end

      it "redirects back to the day page with an alert" do
        post blood_pressure_readings_path, params: { blood_pressure_reading: { systolic: nil, diastolic: 80, date: Date.current } }
        assert_redirected_to day_path_for(Date.current)
        follow_redirect!
        assert_select ".bg-red-50", text: /Systolic can't be blank/
      end
    end
  end

  describe "#edit" do
    it "renders the form inside the turbo frame successfully" do
      get edit_blood_pressure_reading_path @bp_reading
      assert_response :success
      assert_select "turbo-frame#blood_pressure_reading"
    end

    it "won't edit another uer's blood pressure reading" do
      other_entry = users(:two).blood_pressure_readings.first
      get edit_blood_pressure_reading_path other_entry
      assert_response :not_found
    end
  end

  describe "#update" do
    context "with valid params" do
      it "updates the blood pressure reading" do
        patch blood_pressure_reading_path @bp_reading, params: {
          blood_pressure_reading: { systolic: 150, diastolic: 92, date: @bp_reading.date }
        }
        assert_equal "150/92", @bp_reading.reload.combined_value
      end

      it "redirects to the day page after a successful update" do
        patch blood_pressure_reading_path @bp_reading, params: {
          blood_pressure_reading: { systolic: 150, diastolic: 92, date: @bp_reading.date }
        }
        assert_redirected_to day_path_for(@bp_reading.reload)
      end
    end

    context "with invalid params" do
      it "does not update the blood pressure reading" do
        original_blood_pressure_reading = @bp_reading.combined_value
        patch blood_pressure_reading_path @bp_reading, params: {
          blood_pressure_reading: { systolic: nil, diastolic: nil, date: @bp_reading.date }
        }

        assert_equal original_blood_pressure_reading, @bp_reading.reload.combined_value
      end

      it "renders edit with unprocessable entity status" do
        patch blood_pressure_reading_path @bp_reading, params: {
          blood_pressure_reading: { systolic: nil, diastolic: nil, date: @bp_reading.date }
        }
        assert_response :unprocessable_entity
      end

      it "won't edit anotoher user's blood pressure reading" do
        not_own_bp_reading = users(:two).blood_pressure_readings.first
        patch blood_pressure_reading_path not_own_bp_reading, params: {
          blood_pressure_reading: { systolic: 111, diastolic: 67, date: not_own_bp_reading.date }
        }
        assert_response :not_found
      end
    end

    describe "#destroy" do
      context "with valid params" do
        it "deletes the weight entry" do
          assert_difference("BloodPressureReading.count", -1) do
            delete blood_pressure_reading_path @bp_reading
          end
        end

        it "redirects to the day page after a successful deletion" do
          date = @bp_reading.date
          delete blood_pressure_reading_path @bp_reading
          assert_redirected_to day_path_for(date)
        end
      end

      context "with invalid params" do
        it "won't delete another user's blood pressure reading" do
          not_own_bp_reading = users(:two).blood_pressure_readings.first
          delete blood_pressure_reading_path not_own_bp_reading
          assert_response :not_found
        end
      end
    end
  end
end
