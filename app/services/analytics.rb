module  CodeCorps
  class Analytics
    def initialize(user)
      @user = user
    end

    def track_user_created
      identify
      track(user_id: user.id, event: "User created")
    end

    def track_user_signed_in
      identify
      track(user_id: user.id, event: "User signed in")
    end

    private

      def identify
        segment.identify(identify_params)
      end

      def track
        segment.track(options)
      end

      attr_reader :user

      def identify_params
        {
          user_id: user.id,
          traits: user_traits
        }
      end

      def user_traits
        {
          admin: user.admin,
          biography: user.biography,
          created_at: user.created_at,
          email: user.email,
          facebook_id: user.facebook_id,
          name: user.name,
          state: user.state,
          twitter: user.twitter,
          username: user.username
        }.reject { |_key, value| value.blank? }
      end

      def segment
        @segment ||= Segment::Analytics.new(write_key: segment_write_key, stub: stub_analytics?)
      end

      def segment_write_key
        @segment_write_key ||= (ENV["SEGMENT_WRITE_KEY"] || "")
      end

      def stub_analytics?
        @stub_analytics ||= Rails.env.test? || ENV["SEGMENT_WRITE_KEY"].blank?
      end
  end
end
